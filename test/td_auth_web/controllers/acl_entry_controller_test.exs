defmodule TdAuthWeb.AclEntryControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.Permissions
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  import TdAuthWeb.Authentication, only: :functions

  @update_attrs %{resource_id: 43, resource_type: "domain"}
  @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

  setup_all do
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all acl_entries", %{conn: conn} do
      conn = get conn, acl_entry_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema} do
      user = insert(:user)
      # domain = insert(:domain)
      role = Role.role_get_or_create_by_name("watch")
      acl_entry_attrs = build(:acl_entry_resource, principal_id: user.id, resource_id: user.id, role_id: role.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "principal_id" => user.id,
        "principal_type" => "user",
        "resource_id" => user.id,
        "resource_type" => "domain",
        "role_id" => role.id
      }
    end

    @tag :admin_authenticated
    test "renders error for duplicated acl_entry", %{conn: conn, swagger_schema: schema} do
      user = insert(:user)
      # domain = insert(:domain)
      role = Role.role_get_or_create_by_name("watch")
      acl_entry_attrs = build(:acl_entry_resource, principal_id: user.id, resource_id: user.id, role_id: role.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert %{"id" => _id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, acl_entry_path(conn, :create), acl_entry: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "create or update acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when creating a new acl", %{conn: conn, swagger_schema: schema} do
      user = insert(:user)
      # domain = insert(:domain)
      role = Role.role_get_or_create_by_name("create")
      acl_entry_attrs = build(:acl_entry_resource, principal_id: user.id, resource_id: user.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role.name)
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "principal_id" => user.id,
               "principal_type" => "user",
               "resource_id" => user.id,
               "resource_type" => "domain",
               "role_id" => role.id
             }
    end

    test "renders error when creating a new acl without permission", %{} do
      user = insert(:user)
      {:ok, %{conn: conn}} = create_user_auth_conn(user)

      role = Role.role_get_or_create_by_name("create")
      acl_entry_attrs = %{
        principal_id: "10",
        principal_type: "user",
        resource_id: "1",
        resource_type: "domain",
        role_name: role.name
      }
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert json_response(conn, 403)
    end

    @tag :admin_authenticated
    test "updates acl when non admin user has permission", %{} do
      user = insert(:user, user_name: "user1")
      user2 = insert(:user, user_name: "user2")
      Role.role_get_or_create_by_name("role1")
      Role.role_get_or_create_by_name("role2")
      domain_id = "123"

      {:ok, %{conn: conn, claims: %{"jti" => jti, "exp" => exp}}} = create_user_auth_conn(user)
      perms = [%{
        permissions: ["create_acl_entry", "update_acl_entry"],
        resource_id: domain_id,
        resource_type: "domain"
      }]
      Permissions.cache_session_permissions(perms, jti, exp)

      # create acl entry with valid user
      acl_entry_attrs = %{
        principal_id: user2.id,
        principal_type: "user",
        resource_id: domain_id,
        resource_type: "domain",
        role_name: "role1"
      }
      resp = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert json_response(resp, 201)

      # update acl entry with valid user
      acl_entry_attrs = %{
        principal_id: user2.id,
        principal_type: "user",
        resource_id: domain_id,
        resource_type: "domain",
        role_name: "role2"
      }
      resp = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert json_response(resp, 200)
    end

    @tag :admin_authenticated
    test "renders acl_entry when updating an existing acl", %{conn: conn, swagger_schema: schema} do
      user = insert(:user)
      # domain = insert(:domain)
      role = Role.role_get_or_create_by_name("watch")
      acl_entry_attrs = build(:acl_entry_resource, principal_id: user.id, resource_id: user.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role.name)
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => _id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      role = Role.role_get_or_create_by_name("admin")

      conn = recycle_and_put_headers(conn)
      acl_entry_attrs = build(:acl_entry_resource, principal_id: user.id, resource_id: user.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role.name)
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 200)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "principal_id" => user.id,
               "principal_type" => "user",
               "resource_id" => user.id,
               "resource_type" => "domain",
               "role_id" => role.id
             }
    end
  end

  describe "update acl_entry" do
    setup [:create_acl_entry]

    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema, acl_entry: %AclEntry{id: id, role_id: role_id} = acl_entry} do
      conn = put conn, acl_entry_path(conn, :update, acl_entry), acl_entry: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "principal_id" => acl_entry.principal_id,
        "principal_type" => acl_entry.principal_type,
        "resource_id" => @update_attrs.resource_id,
        "resource_type" => @update_attrs.resource_type,
        "role_id" => role_id
       }
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, acl_entry: acl_entry} do
      conn = put conn, acl_entry_path(conn, :update, acl_entry), acl_entry: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete acl_entry" do
    setup [:create_acl_entry]

    @tag :admin_authenticated
    test "deletes chosen acl_entry", %{conn: conn, acl_entry: acl_entry} do
      conn = delete conn, acl_entry_path(conn, :delete, acl_entry)
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, acl_entry_path(conn, :show, acl_entry)
      end
    end
  end

  describe "list acl_entries by resource" do
    setup [:create_acl_entry]

    @tag :admin_authenticated
    test "lists acl_entries by resource", %{conn: conn, acl_entry: acl_entry, user: user} do
      conn = get conn, acl_entry_path(conn, :acl_entries, "domains", acl_entry.resource_id)
      data = json_response(conn, 200)["data"]
      assert length(data) == 1
      [entry] = data
      assert entry["acl_entry_id"] == acl_entry.id
      assert entry["principal_type"] == acl_entry.principal_type
      assert entry["role_id"] == acl_entry.role.id
      assert entry["role_name"] == acl_entry.role.name
      assert entry["principal"]["id"] == user.id
      assert entry["principal"]["user_name"] == user.user_name
      assert entry["principal"]["email"] == user.email
      assert entry["principal"]["full_name"] == user.full_name
      assert entry["principal"]["is_admin"] == user.is_admin
    end

    @tag :admin_authenticated
    test "lists user_roles by resource", %{conn: conn, swagger_schema: schema, acl_entry: acl_entry, user: expected_user} do
      conn = get conn, acl_entry_path(conn, :user_roles, "domains", acl_entry.resource_id)
      validate_resp_schema(conn, schema, "ResourceUserRolesResponse")
      data = json_response(conn, 200)
      assert length(data) == 1
      [entry] = data
      assert entry["role_name"] == acl_entry.role.name
      [user] = entry["users"]
      assert user["id"] == expected_user.id
      assert user["user_name"] == expected_user.user_name
      assert user["full_name"] == expected_user.full_name
    end

  end

  defp create_acl_entry(_) do
    user = insert(:user)
    # domain = insert(:domain)
    role = Role.role_get_or_create_by_name("watch")
    acl_entry_attrs = insert(:acl_entry_resource, principal_id: user.id, resource_id: role.id, role: role)
    {:ok, acl_entry: acl_entry_attrs, user: user}
  end

end
