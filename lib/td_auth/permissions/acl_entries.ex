defmodule TdAuth.Permissions.AclEntries do
  @moduledoc """
  The ACL Entries Context
  """

  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.AclLoader
  alias TdAuth.Permissions.Roles
  alias TdAuth.Repo

  import Ecto.Query

  @type clauses :: %{optional(atom) => term} | keyword

  @doc """
  Gets a single acl_entry.

  Raises `Ecto.NoResultsError` if the Acl entry does not exist.

  ## Examples

      iex> get_acl_entry!(123)
      %AclEntry{}

      iex> get_acl_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_acl_entry!(id), do: Repo.get!(AclEntry, id)

  @doc """
  Returns a list of acl_entries matching the given `filter_clauses`.

  ## Options

    * `:preload` - Preloads the specified associations into the result set. See
      `Ecto.Query.preload/3`. Defaults to `[:group, :role, :user]`.

  """
  @spec list_acl_entries(clauses, keyword) :: [Ecto.Schema.t()]
  def list_acl_entries(filter_clauses \\ [], opts \\ [preload: [:group, :role, :user]]) do
    with preloads <- Keyword.get(opts, :preload, []) do
      AclEntry
      |> do_where(filter_clauses)
      |> preload(^preloads)
      |> Repo.all()
    end
  end

  @doc """
  Creates a new `%AclEntry{}`.

  Returns `{:ok, struct}` if the ACL entry was created successfully or `{:error,
  changeset}` if there was a validation or constraint error.
  """
  def create_acl_entry(%{} = params) do
    params
    |> AclEntry.changeset()
    |> Repo.insert()
    |> refresh_cache()
  end

  @doc """
  Updates an `%AclEntry{}`.

  ## Examples

      iex> update_acl_entry(acl_entry, %{field: new_value})
      {:ok, %AclEntry{}}

      iex> update_acl_entry(acl_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_acl_entry(%AclEntry{} = acl_entry, params) do
    acl_entry
    |> AclEntry.changeset(params)
    |> Repo.update()
    |> refresh_cache()
  end

  def create_or_update(params) do
    case find_by_resource_and_principal(params) do
      %AclEntry{} = acl_entry -> update_acl_entry(acl_entry, params)
      nil -> create_acl_entry(params)
    end
  end

  @doc """
  Deletes a AclEntry.

  ## Examples

      iex> delete_acl_entry(acl_entry)
      {:ok, %AclEntry{}}

      iex> delete_acl_entry(acl_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_acl_entry(%AclEntry{} = acl_entry) do
    acl_entry
    |> Repo.delete()
    |> delete_from_cache()
  end

  def delete_acl_entries(filter_clauses) do
    AclEntry
    |> do_where(filter_clauses)
    |> select([e], e)
    |> Repo.delete_all()
    |> case do
      {count, entries} when count > 0 ->
        Enum.each(entries, &delete_from_cache/1)
        {count, entries}

      res ->
        res
    end
  end

  def get_user_ids_by_resource_and_role(filter_clauses \\ %{}) do
    AclEntry
    |> do_where(filter_clauses)
    |> join(:inner, [e], r in assoc(e, :role))
    |> join(:left, [e, _r], g in assoc(e, :group))
    |> join(:left, [e, _r, g], u in assoc(g, :users))
    |> select([e, r, g, u], {e.resource_type, e.resource_id, r.name, coalesce(e.user_id, u.id)})
    |> where([e, _r, g, u], not is_nil(coalesce(e.user_id, u.id)))
    |> distinct(true)
    |> Repo.all()
    |> Enum.group_by(
      fn {resource_type, resource_id, role, _} -> {resource_type, resource_id, role} end,
      fn {_, _, _, user_id} -> user_id end
    )
  end

  def find_by_resource_and_principal(clauses) do
    clauses
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.take([:resource_type, :resource_id, :user_id, :group_id])
    |> find_acl_entry()
  end

  def find_acl_entry(clauses) do
    Repo.get_by(AclEntry, clauses)
  end

  defp do_where(queryable, filter_clauses) do
    Enum.reduce(filter_clauses, queryable, fn
      {:resource_type, resource_type}, q -> where(q, resource_type: ^resource_type)
      {:resource_id, {:not_in, ids}}, q -> where(q, [e], e.resource_id not in ^ids)
      {:resource_id, resource_id}, q -> where(q, resource_id: ^resource_id)
      {:user_groups, {uid, gids}}, q -> where(q, [e], e.user_id == ^uid or e.group_id in ^gids)
      _, q -> q
    end)
  end

  # ACL Cache

  defp refresh_cache({:ok, struct}), do: refresh_cache(struct)

  defp refresh_cache(%{resource_type: resource_type, resource_id: resource_id} = acl_entry) do
    AclLoader.refresh(resource_type, resource_id)
    {:ok, acl_entry}
  end

  defp refresh_cache(changeset), do: changeset

  defp delete_from_cache({:ok, struct}), do: delete_from_cache(struct)

  defp delete_from_cache(
         %{
           user_id: user_id,
           resource_type: resource_type,
           resource_id: resource_id,
           role_id: role_id
         } = acl_entry
       ) do
    role = Roles.get_role!(role_id)
    AclLoader.delete_acl(resource_type, resource_id, role.name, user_id)
    {:ok, acl_entry}
  end

  defp delete_from_cache(changeset), do: changeset
end
