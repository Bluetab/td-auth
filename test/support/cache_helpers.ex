defmodule TdAuth.CacheHelpers do
  @moduledoc """
  Helper functions for creating and cleaning up cache entries for tests.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdAuth.Factory

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
    put_sessions_permissions(session_id, exp, domain_ids_by_permission)
  end

  def put_sessions_permissions(session_id, exp, domain_ids_by_permission) do
    on_exit(fn -> Redix.del!("session:#{session_id}:domain:permissions") end)

    Permissions.cache_session_permissions!(session_id, exp, %{
      "domain" => domain_ids_by_permission
    })
  end
end
