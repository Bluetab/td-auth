defmodule TdAuthWeb.PermissionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup tags do
    context =
      Enum.reduce(tags, %{}, fn
        {:conn, conn}, acc ->
          Map.put(acc, :conn, put_req_header(conn, "accept", "application/json"))

        _, acc ->
          acc
      end)

    {:ok, context}
  end

  describe "index" do
    @tag authentication: [role: :admin]
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
    @tag authentication: [role: :admin]
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
end
