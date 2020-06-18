defmodule TdAuthWeb.AclEntryControllerTest do
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

  describe "index" do
    @tag :admin_authenticated
    test "lists all acl_entries", %{conn: conn, swagger_schema: schema} do
      assert %{"data" => [_acl_entry]} =
               conn
               |> get(Routes.acl_entry_path(conn, :index))
               |> validate_resp_schema(schema, "AclEntriesResponse")
               |> json_response(:ok)
    end
  end

  describe "create acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema} do
      %{id: user_id} = insert(:user)
      %{id: role_id} = insert(:role)
      resource_id = :rand.uniform(100_000)
      description = "a new ACL to be created"

      acl_entry_attrs = %{
        user_id: user_id,
        role_id: role_id,
        resource_type: "domain",
        resource_id: resource_id,
        description: description
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.acl_entry_path(conn, :create), acl_entry: acl_entry_attrs)
               |> validate_resp_schema(schema, "AclEntryResponse")
               |> json_response(:created)

      assert %{
               "id" => _,
               "group_id" => nil,
               "user_id" => ^user_id,
               "resource_id" => ^resource_id,
               "resource_type" => "domain",
               "role_id" => ^role_id,
               "description" => ^description
             } = data
    end

    @tag :admin_authenticated
    test "renders error for duplicated acl_entry", %{conn: conn, acl_entry: acl_entry} do
      params = Map.take(acl_entry, [:user_id, :group_id, :resource_type, :resource_id, :role_id])

      assert %{"errors" => errors} =
               conn
               |> post(Routes.acl_entry_path(conn, :create), acl_entry: params)
               |> json_response(:unprocessable_entity)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      params = %{"acl_entry" => %{"foo" => "bar"}}

      assert %{"errors" => errors} =
               conn
               |> post(Routes.acl_entry_path(conn, :create), params)
               |> json_response(:unprocessable_entity)
    end
  end

  describe "delete acl_entry" do
    @tag :admin_authenticated
    test "deletes chosen acl_entry", %{conn: conn, acl_entry: acl_entry} do
      assert conn
             |> delete(Routes.acl_entry_path(conn, :delete, acl_entry))
             |> response(:no_content)

      assert_error_sent :not_found, fn ->
        get(conn, Routes.acl_entry_path(conn, :show, acl_entry))
      end
    end
  end
end
