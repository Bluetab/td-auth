defmodule TdAuthWeb.ResourceAclControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    start_supervised!(TdAuth.Permissions.AclLoader)
    :ok
  end

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    acl_entry = insert(:acl_entry, principal_type: :user)
    {:ok, conn: conn, acl_entry: acl_entry}
  end

  @tag :admin_authenticated
  test "show resource acl", %{conn: conn, acl_entry: acl_entry} do
    %{resource_type: resource_type, resource_id: resource_id} = acl_entry

    assert %{"_embedded" => embedded, "_links" => links} =
             conn
             |> get(Routes.resource_acl_path(conn, :show, resource_type, resource_id))
             |> json_response(:ok)

    assert %{"acl_entries" => [_acl_entry]} = embedded
  end
end
