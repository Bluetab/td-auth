defmodule TdAuth.CacheHelpers do
  @moduledoc """
  Helper functions for creating and cleaning up cache entries for tests.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdAuth.Factory

  alias TdCache.AclCache
  alias TdCache.AclCache.Keys
  alias TdCache.Permissions
  alias TdCache.Redix
  alias TdCache.TaxonomyCache
  alias TdCache.UserCache

  def put_domain(params \\ %{}) do
    %{id: domain_id} = domain = build(:domain, params)
    on_exit(fn -> TaxonomyCache.delete_domain(domain_id, clean: true) end)
    TaxonomyCache.put_domain(domain)
    domain
  end

  def put_user(%{} = user) do
    %{id: id} = user = maybe_put_id(user)
    on_exit(fn -> UserCache.delete(id) end)
    UserCache.put(user)
    user
  end

  def put_group(%{} = group) do
    %{id: id} = group = maybe_put_id(group)
    on_exit(fn -> UserCache.delete_group(id) end)
    UserCache.put_group(group)
    group
  end

  defp maybe_put_id(%{id: id} = map) when not is_nil(id), do: map
  defp maybe_put_id(%{} = map), do: Map.put(map, :id, System.unique_integer([:positive]))

  def put_session_permissions(%{} = claims, domain_id, permissions) do
    domain_ids_by_permission = Map.new(permissions, &{to_string(&1), [domain_id]})
    put_session_permissions(claims, domain_ids_by_permission)
  end

  def put_session_permissions(
        %{"jti" => session_id, "exp" => exp},
        %{} = domain_ids_by_permission
      ) do
    on_exit(fn ->
      ["KEYS", "session:*"]
      |> Redix.command!()
      |> Enum.map(&["DEL", &1])
      |> Redix.transaction_pipeline()
    end)

    put_sessions_permissions(session_id, exp, domain_ids_by_permission)
  end

  def put_sessions_permissions(session_id, exp, domain_ids_by_permission) do
    on_exit(fn -> Redix.del!("session:#{session_id}:domain:permissions") end)

    Permissions.cache_session_permissions!(session_id, exp, %{
      "domain" => domain_ids_by_permission
    })
  end

  def put_acl(resource_type, resource_id, role, user_ids) do
    key = Keys.acl_role_users_key(resource_type, resource_id, role)

    on_exit(fn -> Redix.command!(["DEL", key]) end)

    put_user_ids(user_ids)
    AclCache.set_acl_role_users(resource_type, resource_id, role, user_ids)
  end

  def put_user_ids(user_ids) when is_list(user_ids) do
    key = UserCache.ids_key()
    on_exit(fn -> Redix.command!(["SREM", key | List.wrap(user_ids)]) end)
    Redix.command!(["SADD", key | List.wrap(user_ids)])
  end

  def put_roles_by_permission(roles_by_permission) do
    on_exit(fn ->
      ["KEYS", "permission:*:roles"]
      |> Redix.command!()
      |> Enum.map(&["DEL", &1])
      |> Redix.transaction_pipeline()
    end)

    Permissions.put_permission_roles(roles_by_permission)
  end

  def put_default_permissions(permissions) when is_list(permissions) do
    on_exit(fn ->
      Permissions.put_default_permissions([])
    end)

    Permissions.put_default_permissions(permissions)
  end
end
