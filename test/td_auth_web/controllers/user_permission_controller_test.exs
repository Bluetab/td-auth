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

  describe "permission domains" do
    @tag authentication: [role: :user]
    test "renders user permission domains", %{
      conn: conn,
      swagger_schema: schema,
      user: user,
      domain: domain,
      domain2: domain2
    } do
      permission = insert(:permission, name: "view_dashboard")
      q_permission = insert(:permission, name: "view_quality_rule")
      role = insert(:role, permissions: [permission])
      role2 = insert(:role, permissions: [q_permission])

      insert(:acl_entry, user_id: user.id, role: role, resource_id: domain.id)
      insert(:acl_entry, user_id: user.id, role: role2, resource_id: domain2.id)

      conn =
        get(
          conn,
          Routes.user_permissions_path(conn, :show, "me",
            permissions: "view_quality_rule,view_dashboard"
          )
        )

      validate_resp_schema(conn, schema, "PermissionDomainsResponseData")
      permission_domains = json_response(conn, 200)["permission_domains"]
      assert length(permission_domains) == 2
    end

    @tag authentication: [role: :admin]
    test "renders all domains in permission domains for admin user", %{
      conn: conn,
      swagger_schema: schema
    } do
      permission_name = "view_quality_rule"

      conn =
        get(conn, Routes.user_permissions_path(conn, :show, "me", permissions: permission_name))

      validate_resp_schema(conn, schema, "PermissionDomainsResponseData")
      user_data = json_response(conn, 200)["permission_domains"]
      perm_domains = List.first(user_data)
      assert perm_domains["permission"] == permission_name
      assert length(perm_domains["domains"]) > 0
    end
  end
end
