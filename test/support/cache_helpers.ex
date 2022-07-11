defmodule TdAuth.CacheHelpers do
  @moduledoc """
  Helper functions for creating and cleaning up cache entries for tests.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdAuth.Factory

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

  defp maybe_put_id(%{id: id} = map) when not is_nil(id), do: map
  defp maybe_put_id(%{} = map), do: Map.put(map, :id, System.unique_integer([:positive]))
end
