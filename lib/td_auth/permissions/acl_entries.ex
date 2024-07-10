defmodule TdAuth.Permissions.AclEntries do
  @moduledoc """
  The ACL Entries Context
  """

  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.AclLoader
  alias TdAuth.Permissions.RoleLoader
  alias TdAuth.Permissions.Roles
  alias TdAuth.Repo

  import Ecto.Query

  def get_acl_entry!(id), do: Repo.get!(AclEntry, id)

  @spec list_acl_entries(map) :: [Ecto.Schema.t()]
  def list_acl_entries(clauses \\ %{}) do
    clauses = Map.put_new(clauses, :preload, [:group, :role, :user])

    AclEntry
    |> build_query(clauses)
    |> Repo.all()
  end

  def create_acl_entry(%{} = params) do
    params
    |> AclEntry.changeset()
    |> Repo.insert()
    |> refresh_cache()
  end

  def update_acl_entry(%AclEntry{} = acl_entry, params) do
    acl_entry
    |> AclEntry.changeset(params)
    |> Repo.update()
    |> refresh_cache()
  end

  def delete_acl_entry(%AclEntry{group_id: group_id} = acl_entry)
      when not is_nil(group_id) do
    acl_entry
    |> Repo.preload([:role, group: [:users]])
    |> Repo.delete()
    |> delete_user_role_from_cache()
  end

  def delete_acl_entry(%AclEntry{} = acl_entry) do
    acl_entry
    |> Repo.preload(:role)
    |> Repo.delete()
    |> delete_user_role_from_cache()
  end

  def delete_acl_entries(clauses) do
    AclEntry
    |> build_query(clauses)
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

  def get_user_ids_by_resource_and_role(clauses \\ %{}) do
    AclEntry
    |> build_query(clauses)
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

  def get_group_ids_by_resource_and_role(clauses \\ %{}) do
    AclEntry
    |> build_query(clauses)
    |> join(:inner, [e], r in assoc(e, :role))
    |> join(:left, [e, _r], g in assoc(e, :group))
    |> select([e, r, g], {e.resource_type, e.resource_id, r.name, coalesce(e.group_id, g.id)})
    |> where([e, _r, g], not is_nil(coalesce(e.group_id, g.id)))
    |> distinct(true)
    |> Repo.all()
    |> Enum.group_by(
      fn {resource_type, resource_id, role, _} -> {resource_type, resource_id, role} end,
      fn {_, _, _, group_id} -> group_id end
    )
  end

  def find_by_resource_and_principal(clauses) do
    clauses
    |> build_resource_and_principal_clauses()
    |> find_acl_entry()
  end

  defp build_resource_and_principal_clauses(clauses) do
    clauses
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.take([:resource_type, :resource_id, :user_id, :group_id, :role_id])
  end

  def find_acl_entry(clauses) do
    Repo.get_by(AclEntry, clauses)
  end

  defp build_query(queryable, clauses) do
    Enum.reduce(clauses, queryable, fn
      {:resource_type, resource_type}, q -> where(q, resource_type: ^resource_type)
      {:resource_types, resource_types}, q -> where(q, [e], e.resource_type in ^resource_types)
      {:resource_id, {:not_in, ids}}, q -> where(q, [e], e.resource_id not in ^ids)
      {:resource_id, {:in, ids}}, q -> where(q, [e], e.resource_id in ^ids)
      {:resource_id, resource_id}, q -> where(q, resource_id: ^resource_id)
      {:user_groups, {uid, gids}}, q -> where(q, [e], e.user_id == ^uid or e.group_id in ^gids)
      {:user_id, user_id}, q -> where(q, user_id: ^user_id)
      {:group_id, group_id}, q -> where(q, group_id: ^group_id)
      {:preload, preloads}, q -> preload(q, ^preloads)
      {:updated_since, nil}, q -> q
      {:updated_since, ts}, q -> where(q, [e], e.updated_at > ^ts)
      _, q -> q
    end)
  end

  # ACL Cache

  defp refresh_cache({:ok, struct}), do: refresh_cache(struct)

  defp refresh_cache(%{resource_type: resource_type, resource_id: resource_id} = acl_entry) do
    AclLoader.refresh(resource_type, resource_id)
    AclLoader.refresh_group(resource_type, resource_id)
    RoleLoader.load_roles(acl_entry)
    {:ok, acl_entry}
  end

  defp refresh_cache(changeset), do: changeset

  defp delete_user_role_from_cache({:ok, struct}), do: delete_user_role_from_cache(struct)

  defp delete_user_role_from_cache(
         %{resource_type: resource_type, resource_id: resource_id} = acl_entry
       ) do
    AclLoader.refresh(resource_type, resource_id)
    AclLoader.refresh_group(resource_type, resource_id)

    RoleLoader.delete_roles(acl_entry)
    {:ok, acl_entry}
  end

  defp delete_user_role_from_cache(changeset), do: changeset

  defp delete_from_cache({:ok, struct}), do: delete_from_cache(struct)

  defp delete_from_cache(
         %{
           user_id: user_id,
           group_id: group_id,
           resource_type: resource_type,
           resource_id: resource_id,
           role_id: role_id
         } = acl_entry
       ) do
    %{name: role_name} = Roles.get_role!(role_id)

    if is_nil(group_id) do
      AclLoader.delete_acl(resource_type, resource_id, role_name, user_id)
    else
      AclLoader.delete_group_acl(resource_type, resource_id, role_name, group_id)
    end

    {:ok, acl_entry}
  end

  defp delete_from_cache(changeset), do: changeset
end
