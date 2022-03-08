defmodule TdAuthWeb.UserPermissionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"
  alias TdCache.TaxonomyCache

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  setup do
    domain = build(:domain)
    domain2 = build(:domain)
    {:ok, _} = TaxonomyCache.put_domain(domain)
    {:ok, _} = TaxonomyCache.put_domain(domain2)

    on_exit(fn ->
      TaxonomyCache.delete_domain(domain.id)
      TaxonomyCache.delete_domain(domain2.id)
    end)

    [domain: domain, domain2: domain2]
  end
end
