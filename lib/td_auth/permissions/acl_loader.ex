defmodule TdAuth.Permissions.AclLoader do
  @moduledoc """
  Loads ACL entries into distributed cache.
  """

  alias TdAuth.Permissions.AclEntries
  alias TdCache.AclCache

  def load_cache do
    AclEntries.get_user_ids_by_resource_and_role()
    |> put_cache()
    AclEntries.get_group_ids_by_resource_and_role()
    |> put_group_cache()
  end

  def refresh(resource_type, resource_id) do
    acls =
      AclEntries.get_user_ids_by_resource_and_role(
        resource_type: resource_type,
        resource_id: resource_id
      )

    if map_size(acls) == 0 do
      delete_resource(resource_type, resource_id)
    else
      put_cache(acls)
    end
  end

  def refresh_group(resource_type, resource_id) do
    acls =
      AclEntries.get_group_ids_by_resource_and_role(
        resource_type: resource_type,
        resource_id: resource_id
      )

    if map_size(acls) == 0 do
      delete_group_resource(resource_type, resource_id)
    else
      put_group_cache(acls)
    end
  end

  def delete(resource_type, resource_id) do
    delete_resource(resource_type, resource_id)
  end

  def delete_group(resource_type, resource_id) do
    delete_group_resource(resource_type, resource_id)
  end

  def delete_acl(resource_type, resource_id, role, user_id) do
    AclCache.delete_acl_role_user(resource_type, resource_id, role, user_id)
  end

  def delete_group_acl(resource_type, resource_id, role, group_id) do
    AclCache.delete_acl_role_user(resource_type, resource_id, role, group_id)
  end

  defp delete_resource(resource_type, resource_id) do
    roles = AclCache.get_acl_roles(resource_type, resource_id)

    Enum.each(roles, fn role ->
      {:ok, _} = AclCache.delete_acl_role_users(resource_type, resource_id, role)
    end)

    {:ok, _} = AclCache.delete_acl_roles(resource_type, resource_id)
  end

  defp delete_group_resource(resource_type, resource_id) do
    roles = AclCache.get_acl_group_roles(resource_type, resource_id)

    Enum.each(roles, fn role ->
      {:ok, _} = AclCache.delete_acl_role_groups(resource_type, resource_id, role)
    end)

    {:ok, _} = AclCache.delete_acl_group_roles(resource_type, resource_id)
  end

  defp put_cache(%{} = user_ids_by_resource_and_role) do
    user_ids_by_resource_and_role
    |> Enum.map(fn {{resource_type, resource_id, role} = key, user_ids} ->
      {:ok, _} = AclCache.set_acl_role_users(resource_type, resource_id, role, user_ids)
      key
    end)
    |> Enum.group_by(
      fn {resource_type, resource_id, _} -> {resource_type, resource_id} end,
      fn {_, _, role} -> role end
    )
    |> Enum.each(fn {{resource_type, resource_id}, roles} ->
      {:ok, _} = AclCache.set_acl_roles(resource_type, resource_id, roles)
    end)
  end

  defp put_group_cache(%{} = group_ids_by_resource_and_role) do
    group_ids_by_resource_and_role
    |> Enum.map(fn {{resource_type, resource_id, role} = key, group_ids} ->
      {:ok, _} = AclCache.set_acl_role_groups(resource_type, resource_id, role, group_ids)
      key
    end)
    |> Enum.group_by(
      fn {resource_type, resource_id, _} -> {resource_type, resource_id} end,
      fn {_, _, role} -> role end
    )
    |> Enum.each(fn {{resource_type, resource_id}, roles} ->
      {:ok, _} = AclCache.set_acl_group_roles(resource_type, resource_id, roles)
    end)
  end
end
