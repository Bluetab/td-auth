defmodule TdAuthWeb.AclEntryControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import Routes, only: [acl_entry_path: 2, acl_entry_path: 3]

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    start_supervised!(TdAuth.Permissions.AclLoader)
    :ok
  end

  setup do
    [acl_entry: insert(:acl_entry, principal_type: :user)]
  end

  describe "GET /api/acl_entries" do
    @tag authentication: [role: :admin]
    test "admin can view acl entries", %{conn: conn, swagger_schema: schema} do
      assert %{"data" => [_acl_entry]} =
               conn
               |> get(acl_entry_path(conn, :index))
               |> validate_resp_schema(schema, "AclEntriesResponse")
               |> json_response(:ok)
    end

    @tag authentication: [role: :service]
    test "service account can view acl entries", %{conn: conn} do
      assert %{"data" => [_acl_entry]} =
               conn
               |> get(acl_entry_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: :user]
    test "user account cannot list acl entries", %{conn: conn} do
      assert %{"errors" => _errors} =
               conn
               |> get(acl_entry_path(conn, :index))
               |> json_response(:forbidden)
    end
  end

  describe "GET /api/acl_entries/:id" do
    @tag authentication: [role: :admin]
    test "returns an acl entry", %{conn: conn, acl_entry: acl_entry, swagger_schema: schema} do
      %{id: id} = acl_entry

      assert %{"data" => %{"id" => ^id}} =
               conn
               |> get(acl_entry_path(conn, :show, acl_entry))
               |> validate_resp_schema(schema, "AclEntryResponse")
               |> json_response(:ok)
    end
  end

  describe "POST /api/acl_entries" do
    @tag authentication: [role: :admin]
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
               |> post(acl_entry_path(conn, :create), acl_entry: acl_entry_attrs)
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

    @tag authentication: [role: :admin]
    test "renders error for duplicated acl_entry", %{conn: conn, acl_entry: acl_entry} do
      params = Map.take(acl_entry, [:user_id, :group_id, :resource_type, :resource_id, :role_id])

      assert %{"errors" => errors} =
               conn
               |> post(acl_entry_path(conn, :create), acl_entry: params)
               |> json_response(:unprocessable_entity)

      assert errors == %{"user_id" => ["taken"]}
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn} do
      params = %{"acl_entry" => %{"foo" => "bar"}}

      assert %{"errors" => errors} =
               conn
               |> post(acl_entry_path(conn, :create), params)
               |> json_response(:unprocessable_entity)

      assert errors == %{
               "resource_id" => ["can't be blank"],
               "resource_type" => ["can't be blank"],
               "role_id" => ["can't be blank"]
             }
    end
  end

  describe "DELETE /api/acl_entries/:id" do
    @tag authentication: [role: :admin]
    test "deletes chosen acl_entry", %{conn: conn, acl_entry: acl_entry} do
      assert conn
             |> delete(acl_entry_path(conn, :delete, acl_entry))
             |> response(:no_content)

      assert_error_sent :not_found, fn ->
        get(conn, acl_entry_path(conn, :show, acl_entry))
      end
    end
  end
end
