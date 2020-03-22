defmodule TdAuthWeb.RolePermissionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

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

  describe "role permissions" do
    @tag :admin_authenticated
    @tag role: %{name: "test", permissions: ["permission1", "permission2"]}
    test "list role permissions", %{conn: conn, swagger_schema: schema, role: role} do
      assert %{"data" => data} =
               conn
               |> get(Routes.role_role_permission_path(conn, :show, role.id))
               |> validate_resp_schema(schema, "PermissionsResponse")
               |> json_response(:ok)

      permission_names = Enum.map(data, & &1["name"])
      assert_lists_equal(permission_names, ["permission1", "permission2"])
    end

    @tag :admin_authenticated
    @tag role: %{name: "test", permissions: ["permission1", "permission2"]}
    test "modify role permissions", %{conn: conn, swagger_schema: schema, role: role} do
      assert %{id: role_id, permissions: [%{id: permission_id1}, %{id: permission_id2}]} = role
      id_params = [%{"id" => permission_id1}, %{"id" => permission_id2}]

      assert %{"data" => data} =
               conn
               |> put(Routes.role_role_permission_path(conn, :update, role.id),
                 permissions: id_params
               )
               |> validate_resp_schema(schema, "PermissionsResponse")
               |> json_response(:ok)

      assert_lists_equal(data, id_params, &(&1["id"] == &2["id"]))
    end
  end
end
