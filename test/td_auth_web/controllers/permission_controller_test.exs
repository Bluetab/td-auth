defmodule TdAuthWeb.PermissionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.Role

  setup_all do
    :ok
  end

  setup %{conn: conn} = context do
    role_id = case context[:role] do
      %{name: role_name, permissions: permission_names} ->
        permissions = permission_names
          |> Enum.map(&(get_or_create_permission/1))
        %{id: role_id} = Role.role_get_or_create_by_name(role_name)
          |> Role.add_permissions_to_role(permissions)
        role_id
      _ -> nil
    end

    {:ok, conn: put_req_header(conn, "accept", "application/json"), role_id: role_id}
  end

  defp get_or_create_permission(name) do
    case Permissions.get_permission_by_name(name) do
      nil -> 
        {:ok, p} = Permissions.create_permission(%{name: name})
        p
      p -> p
    end
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all permissions", %{conn: conn, swagger_schema: schema} do
      conn = get conn, permission_path(conn, :index)
      validate_resp_schema(conn, schema, "PermissionsResponse")
      collection = json_response(conn, 200)["data"]
      stored_permissions = collection
        |> Enum.map(&Map.get(&1, "name"))
        #|> Enum.filter(&(&1 != "test"))
        |> Enum.sort
      current_permissions = Permission.permissions |> Map.values |> Enum.sort
      assert stored_permissions == current_permissions
    end
  end

  describe "show" do
    @tag :admin_authenticated
    test "show permission", %{conn: conn, swagger_schema: schema} do
      conn = get conn, permission_path(conn, :index)
      collection = json_response(conn, 200)["data"]
      permission = List.first(collection)
      permission_id = Map.get(permission, "id")

      conn = recycle_and_put_headers(conn)
      conn = get conn, permission_path(conn, :show, permission_id)
      validate_resp_schema(conn, schema, "PermissionResponse")
      assert permission == json_response(conn, 200)["data"]
    end
  end

  describe "role permissions" do

    @tag :admin_authenticated
    @tag role: %{name: "test", permissions: ["permission1", "permission2"]}
    test "list role permissions", %{conn: conn, swagger_schema: schema, role_id: role_id} do
      conn = recycle_and_put_headers(conn)
      conn = get conn, role_permission_path(conn, :get_role_permissions, role_id)
      validate_resp_schema(conn, schema, "PermissionsResponse")
      collection = json_response(conn, 200)["data"] |> Enum.map(&(Map.get(&1, "name")))
      assert collection == ["permission1", "permission2"]
    end

    @role_attrs %{name: "rolename"}

    @tag :admin_authenticated
    test "add permissions to role", %{conn: conn, swagger_schema: schema} do
      conn = get conn, permission_path(conn, :index)
      permissions = json_response(conn, 200)["data"]
      permissions = Enum.sort(permissions, &(Map.get(&1, "name") < Map.get(&2, "name")))

      conn = recycle_and_put_headers(conn)
      conn = post conn, role_path(conn, :create), role: @role_attrs
      validate_resp_schema(conn, schema, "RoleResponse")
      %{"id" => role_id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = post conn, role_permission_path(conn, :add_permissions_to_role, role_id), permissions: permissions
      validate_resp_schema(conn, schema, "PermissionsResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, role_permission_path(conn, :get_role_permissions, role_id)
      validate_resp_schema(conn, schema, "PermissionsResponse")
      stored_permissions = json_response(conn, 200)["data"]
      stored_permissions = Enum.sort(stored_permissions, &(Map.get(&1, "name") < Map.get(&2, "name")))

      assert permissions == stored_permissions
    end

  end

end
