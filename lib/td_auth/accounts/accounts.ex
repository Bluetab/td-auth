defmodule TdAuth.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Accounts.UserLoader
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Repo

  def user_exists? do
    Repo.exists?(User)
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(opts \\ []) do
    filter_clauses = Keyword.put_new(opts, :is_protected, false)

    User
    |> do_where(filter_clauses)
    |> Repo.all()
  end

  defp do_where(queryable, filter_clauses) do
    Enum.reduce(filter_clauses, queryable, fn
      {:is_protected, is_protected}, q -> where(q, is_protected: ^is_protected)
      {:id, {:in, ids}}, q -> where(q, [u], u.id in ^ids)
      {:preload, preloads}, q -> preload(q, ^preloads)
      _, q -> q
    end)
  end

  def list_users_by_group_id(group_id) do
    group = get_group!(group_id)
    Repo.all(Ecto.assoc(group, :users))
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
  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> refresh_cache()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> refresh_cache()
  end

  @doc """
  Update a user from a profile. Creates the user if it doesn't exist
  """
  def create_or_update_user(profile) do
    user_name = Map.get(profile, "user_name") || Map.get(profile, :user_name)
    user = get_user_by_name(user_name)

    case user do
      nil -> create_user(profile)
      u -> update_user(u, profile)
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
    |> delete_cache()
  end

  @doc """
  Returns the acl entries associated with a user or its groups.
  """
  def get_user_acls(%User{id: user_id}) do
    get_user_acls(user_id)
  end

  @doc """
  Returns the acl entries associated with a user_id or its groups.
  """
  def get_user_acls(user_id) do
    group_ids =
      "users_groups"
      |> where(user_id: ^user_id)
      |> select([ug], ug.group_id)
      |> Repo.all()

    AclEntries.list_acl_entries(resource_type: "domain", user_groups: {user_id, group_ids})
  end

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups do
    Repo.all(Group)
  end

  def list_groups(ids) do
    Repo.all(from(u in Group, where: u.id in ^ids))
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
  def get_group(id), do: Repo.get(Group, id)

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
  end

  def get_group_by_name(name) do
    Repo.get_by(Group, name: name)
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
  end

  defp put_users(%{"user_ids" => user_ids} = params) do
    users = list_users(id: {:in, user_ids})

    params
    |> Map.delete("user_ids")
    |> Map.put("users", users)
  end

  defp put_users(params), do: params

  @doc """
  Deletes a Group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  def delete_group_from_user(%User{} = user, %Group{} = group) do
    user = Repo.preload(user, :groups)
    groups = Enum.filter(user.groups, &(&1.name != group.name))

    user
    |> Changeset.change()
    |> Changeset.put_assoc(:groups, groups)
    |> Repo.update()
  end

  def add_groups_to_user(%User{} = user, groups) do
    user
    |> Repo.preload(:groups)
    |> User.link_to_groups_changeset(groups)
    |> Repo.update()
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

  defp refresh_cache({:ok, %{id: id} = user}) do
    UserLoader.refresh(id)
    {:ok, user}
  end

  defp refresh_cache(result), do: result

  defp delete_cache({:ok, %{id: id} = user}) do
    UserLoader.delete(id)
    {:ok, user}
  end

  defp delete_cache(result), do: result
end
