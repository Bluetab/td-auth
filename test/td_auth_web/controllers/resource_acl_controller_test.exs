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

  describe "show resource acl" do
    @tag :admin_authenticated
    test "returns OK and body on success", %{
      conn: conn,
      acl_entry: acl_entry,
      swagger_schema: schema
    } do
      %{resource_type: resource_type, resource_id: resource_id} = acl_entry

      assert %{"_embedded" => embedded, "_links" => links} =
               conn
               |> get(Routes.resource_acl_path(conn, :show, resource_type, resource_id))
               |> validate_resp_schema(schema, "ResourceAclEntriesResponse")
               |> json_response(:ok)

      assert %{"acl_entries" => [_acl_entry]} = embedded
    end
  end

  describe "patch resource acl entries" do
    @tag :admin_authenticated
    test "add an entry to a resource acl", %{
      conn: conn,
      acl_entry: acl_entry,
      swagger_schema: schema
    } do
      %{resource_type: resource_type, resource_id: resource_id} = acl_entry

      %{id: user_id} = insert(:user)
      %{name: role_name} = insert(:role)
      description = "a new ACL to be added"

      params = %{
        "acl_entry" => %{
          "principal_type" => "user",
          "principal_id" => user_id,
          "role_name" => role_name,
          "description" => description
        }
      }

      conn1 = patch(conn, Routes.resource_acl_path(conn, :update, resource_type, resource_id, params))

      assert response(conn1, :see_other)
      assert [location] = get_resp_header(conn1, "location")
      assert location == "/api/domain/#{resource_id}/acl_entries"

      assert %{"_embedded" => embedded, "_links" => links} =
               conn
               |> get(location, %{})
               |> validate_resp_schema(schema, "ResourceAclEntriesResponse")
               |> json_response(:ok)

      assert %{"acl_entries" => [_acl_entry1, _acl_entry2]} = embedded
    end

    @tag :admin_authenticated
    test "modify an entry in a resource acl", %{
      conn: conn,
      acl_entry: acl_entry,
      swagger_schema: schema
    } do
      %{resource_type: resource_type, resource_id: resource_id, user_id: user_id} = acl_entry
      %{name: role_name} = insert(:role)

      params = %{
        "acl_entry" => %{
          "principal_type" => "user",
          "principal_id" => user_id,
          "role_name" => role_name
        }
      }

      conn1 =
        patch(conn, Routes.resource_acl_path(conn, :update, resource_type, resource_id, params))

      assert response(conn1, :see_other)
      assert [location] = get_resp_header(conn1, "location")
      assert location == "/api/domain/#{resource_id}/acl_entries"

      assert %{"_embedded" => embedded, "_links" => links} =
               conn
               |> get(location, %{})
               |> validate_resp_schema(schema, "ResourceAclEntriesResponse")
               |> json_response(:ok)

      assert %{"acl_entries" => [%{"role_name" => role_name}]} = embedded
    end

    @tag :authenticated_user
    test "returns forbidden when user is not authorized", %{conn: conn} do
      user = insert(:user)
      role = insert(:role)

      params = %{
        "acl_entry" => %{
          "principal_type" => "user",
          "principal_id" => user.id,
          "role_name" => role.name
        }
      }

      assert conn
             |> patch(Routes.resource_acl_path(conn, :update, "domain", "1"), params)
             |> json_response(:forbidden)
    end
  end
end
