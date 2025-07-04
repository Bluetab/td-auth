defmodule TdAuth.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias TdAuth.Accounts.{Group, GroupLoader, User, UserLoader}
  alias TdAuth.Map.Helpers
  alias TdAuth.Permissions.{AclEntries, AclEntry, AclLoader, Permission, RolePermission}
  alias TdAuth.Repo
  alias TdCache.Permissions

  def user_exists? do
    User
    |> where([u], u.role == :admin)
    |> Repo.exists?(role: :admin)
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(opts \\ [])

  def list_users(opts) do
    User
    |> apply_list_users_opts(opts)
    |> Repo.all()
  end

  defp prepare_joins(queryable, filter_clauses) do
    Enum.reduce_while(filter_clauses, queryable, fn
      {:domains, _}, q -> {:halt, users_groups_acl_join(q)}
      {:permission_on_domains, _}, q -> {:halt, users_groups_acl_join(q)}
      {:roles, _}, q -> {:halt, users_groups_acl_join(q)}
      _, q -> {:cont, q}
    end)
  end

  defp apply_list_users_opts(queryable, filter_clauses) do
    filtered_filter_clauses =
      filter_clauses
      |> Keyword.get(:permission_on_domains)
      |> permission_in_default_rol(filter_clauses)

    queryable = prepare_joins(queryable, filtered_filter_clauses)

    Enum.reduce(filtered_filter_clauses, queryable, fn
      {:role, role}, q ->
        where(q, role: ^role)

      {:roles, role_ids}, q ->
        where(q, [ae: ae], ae.role_id in ^role_ids)

      {:id, {:in, ids}}, q ->
        where(q, [u], u.id in ^ids)

      {:preload, preloads}, q ->
        preload(q, ^preloads)

      {:limit, max_results}, q ->
        limit(q, ^max_results)

      {:query, query}, q ->
        where(
          q,
          [u],
          ilike(u.full_name, ^query) or ilike(u.email, ^query) or ilike(u.user_name, ^query)
        )

      {:permission_on_domains, {permission, domain_ids}}, q ->
        permission_on_domains_query(q, permission, domain_ids)

      {:domains, domain_ids}, q ->
        where(q, [ae: ae], ae.resource_id in ^domain_ids)

      _, q ->
        q
    end)
    |> group_by([u], u.id)
  end

  defp permission_on_domains_query(query, permission, domain_ids) do
    query
    |> join(:inner, [ae: ae], rp in RolePermission, as: :rp, on: rp.role_id == ae.role_id)
    |> join(:inner, [rp: rp], p in Permission, as: :p, on: p.id == rp.permission_id)
    |> where([p: p], p.name == ^permission)
    |> where([ae: ae], ae.resource_id in ^domain_ids)
  end

  defp users_groups_acl_join(query) do
    query
    |> join(:left, [u], ug in "users_groups", as: :ug, on: ug.user_id == u.id)
    |> join(:inner, [u, ug: ug], ae in AclEntry,
      as: :ae,
      on: ae.group_id == ug.group_id or ae.user_id == u.id
    )
    |> where([ae: ae], ae.resource_type == "domain")
  end

  def permission_in_default_rol(nil, filter_clauses), do: filter_clauses

  def permission_in_default_rol({permission, _}, filter_clauses) do
    RolePermission
    |> join(:left, [rp], r in assoc(rp, :role))
    |> join(:left, [rp], p in assoc(rp, :permission))
    |> where([rp, r, p], p.name == ^permission)
    |> where([rp, r, p], r.is_default == true)
    |> select([rp, r, p], %{rol_id: rp.role_id, permission_id: rp.permission_id})
    |> Repo.one()
    |> case do
      nil -> filter_clauses
      _ -> Keyword.delete(filter_clauses, :permission_on_domains)
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id, opts \\ []), do: get!(User, id, opts)

  def get_user_by_name(user_name) do
    User
    |> Repo.get_by(user_name: String.downcase(user_name))
    |> Repo.preload(:groups)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(params) do
    params = put_groups(params)

    %User{}
    |> User.changeset(params)
    |> Repo.insert()
    |> post_upsert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, params, keep_groups \\ false) do
    params = put_groups(params)

    user
    |> Repo.preload(:groups)
    |> User.changeset(params, keep_groups)
    |> Repo.update()
    |> post_upsert()
  end

  @doc """
  Update a user from a profile. Creates the user if it doesn't exist
  """
  def create_or_update_user(profile, keep_groups \\ false) do
    user_name = Map.get(profile, "user_name") || Map.get(profile, :user_name)

    case get_user_by_name(user_name) do
      nil ->
        create_user(Helpers.stringify_keys(profile))

      user ->
        update_user(user, Helpers.stringify_keys(profile), keep_groups)
    end
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    user
    |> Repo.delete()
    |> post_delete()
  end

  @doc """
  Returns the acl entries associated with a user or its groups.
  """
  def get_user_acls(user_or_user_id)

  def get_user_acls(%User{id: user_id}) do
    get_user_acls(user_id)
  end

  def get_user_acls(user_id) do
    group_ids =
      "users_groups"
      |> where(user_id: ^user_id)
      |> select([ug], ug.group_id)
      |> Repo.all()

    AclEntries.list_acl_entries(%{resource_type: "domain", user_groups: {user_id, group_ids}})
  end

  @doc """
  Returns the acl entries with specified preloads associated with user_id or its groups
  """
  def get_user_acls(user_id, preloads) do
    user = get_user!(user_id, preload: :groups)
    group_ids = Enum.map(user.groups, & &1.id)

    AclEntries.list_acl_entries(%{
      resource_type: "domain",
      user_groups: {user_id, group_ids},
      preload: preloads
    })
  end

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups(opts \\ []) do
    Group
    |> apply_list_groups_opts(opts)
    |> Repo.all()
  end

  defp apply_list_groups_opts(queryable, filter_clauses) do
    Enum.reduce(filter_clauses, queryable, fn
      {:preload, preloads}, q -> preload(q, ^preloads)
      {:limit, max_results}, q -> limit(q, ^max_results)
      {:query, query}, q -> where(q, [u], ilike(u.name, ^query) or ilike(u.description, ^query))
      _, q -> q
    end)
  end

  @doc """
  Gets a single group.

  Raises `Ecto.NoResultsError` if the Group does not exist.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group!(id, opts \\ []), do: get!(Group, id, opts)

  @doc """
  Gets a single group.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      nil

  """
  def get_group(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Group
    |> preload(^preload)
    |> Repo.get(id)
  end

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Group{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(params \\ %{}) do
    params = put_users(params)

    %Group{}
    |> Group.changeset(params)
    |> Repo.insert()
    |> post_group_upsert()
  end

  @doc """
  Updates a group.

  ## Examples

      iex> update_group(group, %{field: new_value})
      {:ok, %Group{}}

      iex> update_group(group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group(%Group{} = group, params) do
    params = put_users(params)

    group
    |> Group.changeset(params)
    |> Repo.update()
    |> post_group_upsert()
    |> refresh_cache()
  end

  # ACL Cache

  defp refresh_cache({:ok, group}), do: refresh_cache(group)

  defp refresh_cache(%Group{id: id} = group) do
    group_domains = AclEntries.list_acl_entries(%{resource_type: "domain", group_id: id})
    do_refresh_cache(group_domains)
    {:ok, group}
  end

  defp refresh_cache(changeset), do: changeset

  defp refresh_cache(%Group{} = group, group_domains) do
    do_refresh_cache(group_domains)
    {:ok, group}
  end

  defp refresh_cache({:ok, group}, group_domains) do
    refresh_cache(group, group_domains)
  end

  defp refresh_cache(changeset, _group_domains) do
    changeset
  end

  defp do_refresh_cache(group_domains) do
    group_domains
    |> Enum.map(&Map.get(&1, :resource_id))
    |> Enum.uniq()
    |> Enum.each(&AclLoader.refresh("domain", &1))
  end

  @doc """
  Deletes a Group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    group_domains = AclEntries.list_acl_entries(%{resource_type: "domain", group_id: group.id})

    group
    |> Repo.delete()
    |> post_group_delete()
    |> refresh_cache(group_domains)
  end

  defp get!(queryable, id, opts) do
    case Keyword.get(opts, :preload) do
      nil ->
        Repo.get!(queryable, id)

      preloads ->
        queryable
        |> Repo.get!(id)
        |> Repo.preload(preloads)
    end
  end

  defp post_upsert({:ok, %User{id: id} = user}) do
    UserLoader.refresh(id)
    {:ok, Repo.preload(user, :groups)}
  end

  defp post_upsert(result), do: result

  defp post_delete({:ok, %User{id: id} = user}) do
    UserLoader.delete(id)
    {:ok, user}
  end

  defp post_delete(result), do: result

  defp post_group_upsert({:ok, %Group{id: id} = group}) do
    GroupLoader.refresh(id)
    {:ok, group}
  end

  defp post_group_upsert(result), do: result

  defp post_group_delete({:ok, %Group{id: id} = group}) do
    GroupLoader.delete(id)
    {:ok, group}
  end

  defp post_group_delete(result), do: result

  defp put_users(%{"user_ids" => user_ids} = params) do
    users = list_users(id: {:in, user_ids})

    params
    |> Map.delete("user_ids")
    |> Map.put("users", users)
  end

  defp put_users(params), do: params

  defp put_groups(%{"groups" => group_names} = params) do
    groups_or_changesets =
      Enum.map(group_names, fn group_name ->
        case Repo.get_by(Group, name: group_name) do
          %Group{} = group -> group
          nil -> Group.changeset(%{name: group_name})
        end
      end)

    Map.put(params, "groups", groups_or_changesets)
  end

  defp put_groups(params), do: params

  def get_requestable_users(user_id, params) do
    User
    |> prepare_request_joins(params)
    |> avoid_requester_user(user_id)
    |> apply_filters(params)
    |> select_fields
    |> Repo.all()
    |> filter_by_structures_domains(params)
  end

  defp prepare_request_joins(queryable, filter_clauses) do
    Enum.reduce_while(filter_clauses, queryable, fn
      {"filter_domains", _}, q -> {:halt, users_groups_acl_join(q)}
      {"roles", _}, q -> {:halt, users_groups_acl_join(q)}
      _, q -> {:cont, q}
    end)
  end

  defp avoid_requester_user(q, user_id), do: where(q, [u], u.id != ^user_id)

  defp apply_filters(queryable, filters) do
    filters
    |> Enum.reduce(queryable, fn
      {"query", query}, q ->
        querylike = "%#{query}%"

        where(
          q,
          [u],
          ilike(u.full_name, ^querylike) or ilike(u.email, ^querylike) or
            ilike(u.user_name, ^querylike)
        )

      {"roles", role_ids}, q ->
        where(q, [ae: ae], ae.role_id in ^role_ids)

      {"filter_domains", domain_ids}, q ->
        where(q, [ae: ae], ae.resource_id in ^domain_ids)

      _, q ->
        q
    end)
    |> group_by([u], u.id)
  end

  defp select_fields(queryable) do
    select(queryable, [u], %{id: u.id, full_name: u.full_name, role: u.role})
  end

  defp filter_by_structures_domains(users, %{"structures_domains" => structures_domains}) do
    Enum.filter(users, fn %{id: id, role: role} ->
      permitted_domains =
        Permissions.permitted_domain_ids_by_user_id(id, :allow_foreign_grant_request)

      Enum.member?([:admin], role) or
        Enum.all?(structures_domains, fn domain ->
          domain in permitted_domains
        end)
    end)
  end
end
