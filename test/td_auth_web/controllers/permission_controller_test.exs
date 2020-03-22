defmodule TdAuthWeb.PermissionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  setup tags do
    context =
      Enum.reduce(tags, %{}, fn
        {:conn, conn}, acc ->
          Map.put(acc, :conn, put_req_header(conn, "accept", "application/json"))

        {:role, %{name: role_name, permissions: permission_names}}, acc ->
          permissions = Enum.map(permission_names, &build(:permission, name: &1))
          Map.put(acc, :role, insert(:role, name: role_name, permissions: permissions))

        _, acc ->
          acc
      end)

    {:ok, context}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all permissions", %{conn: conn, swagger_schema: schema} do
      expected =
        1..5
        |> Enum.map(fn _ -> insert(:permission) end)
        |> Enum.map(fn
          %{id: id, name: name, permission_group: %{id: group_id, name: group_name}} ->
            %{"id" => id, "name" => name, "group" => %{"id" => group_id, "name" => group_name}}
        end)

      assert %{"data" => data} =
               conn
               |> get(Routes.permission_path(conn, :index))
               |> validate_resp_schema(schema, "PermissionsResponse")
               |> json_response(:ok)

      assert_lists_equal(
        data,
        expected,
        &assert_maps_equal(&1, &2, ["id", "name", "group"])
      )
    end
  end

  describe "show" do
    @tag :admin_authenticated
    test "show permission", %{conn: conn, swagger_schema: schema} do
      %{id: id, name: name, permission_group: %{id: group_id, name: group_name}} =
        insert(:permission)

      assert %{"data" => data} =
               conn
               |> get(Routes.permission_path(conn, :show, id))
               |> validate_resp_schema(schema, "PermissionResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "name" => ^name, "group" => group} = data
      assert %{"id" => ^group_id, "name" => ^group_name} = group
    end
  end

  describe "role permissions" do
    @tag :admin_authenticated
    @tag role: %{name: "test", permissions: ["permission1", "permission2"]}
    test "list role permissions", %{conn: conn, swagger_schema: schema, role: role} do
      conn = recycle_and_put_headers(conn)
      conn = get(conn, Routes.role_permission_path(conn, :get_role_permissions, role.id))
      validate_resp_schema(conn, schema, "PermissionsResponse")
      collection = json_response(conn, :ok)["data"] |> Enum.map(&Map.get(&1, "name"))
      assert collection == ["permission1", "permission2"]
    end

    @tag :admin_authenticated
    test "add permissions to role", %{conn: conn, swagger_schema: schema} do
      conn = get(conn, Routes.permission_path(conn, :index))
      permissions = json_response(conn, :ok)["data"]
      permissions = Enum.sort(permissions, &(Map.get(&1, "name") < Map.get(&2, "name")))

      conn = recycle_and_put_headers(conn)
      conn = post(conn, Routes.role_path(conn, :create), role: %{name: "rolename"})
      validate_resp_schema(conn, schema, "RoleResponse")
      %{"id" => role_id} = json_response(conn, :created)["data"]

      conn = recycle_and_put_headers(conn)

      conn =
        post conn, Routes.role_permission_path(conn, :add_permissions_to_role, role_id),
          permissions: permissions

      validate_resp_schema(conn, schema, "PermissionsResponse")

      conn = recycle_and_put_headers(conn)
      conn = get(conn, Routes.role_permission_path(conn, :get_role_permissions, role_id))
      validate_resp_schema(conn, schema, "PermissionsResponse")
      stored_permissions = json_response(conn, :ok)["data"]

      stored_permissions =
        Enum.sort(stored_permissions, &(Map.get(&1, "name") < Map.get(&2, "name")))

      assert permissions == stored_permissions
    end
  end
end
