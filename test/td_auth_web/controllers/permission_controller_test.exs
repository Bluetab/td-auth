defmodule TdAuthWeb.PermissionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)

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

  describe "create" do
    @tag authentication: [role: :user]
    test "non-admin user cannot create permissions", %{conn: conn, swagger_schema: schema} do
      %{id: permission_group_id} =
        insert(:permission_group, name: "#{@custom_prefix}permission_group")

      params = %{
        "name" => "non_custom_permission_name",
        "permission_group_id" => permission_group_id
      }

      assert conn
             |> post(Routes.permission_path(conn, :create), permission: params)
             |> validate_resp_schema(schema, "PermissionResponse")
             |> json_response(:forbidden)
    end

    @tag authentication: [role: :admin]
    test "create non-custom permission returns error", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{id: permission_group_id} =
        insert(:permission_group, name: "#{@custom_prefix}permission_group")

      params = %{
        "name" => "non_custom_permission_name",
        "permission_group_id" => permission_group_id
      }

      assert %{"errors" => errors} =
               conn
               |> post(Routes.permission_path(conn, :create), permission: params)
               |> validate_resp_schema(schema, "PermissionResponse")
               |> json_response(:unprocessable_entity)

      assert %{"name" => _name_errors} = errors
    end

    @tag authentication: [role: :admin]
    test "create custom permission", %{conn: conn, swagger_schema: schema} do
      %{id: permission_group_id} =
        insert(:permission_group, name: "#{@custom_prefix}permission_group")

      params = %{
        "name" => "#{@custom_prefix}permission_name",
        "permission_group_id" => permission_group_id
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.permission_path(conn, :create), permission: params)
               |> validate_resp_schema(schema, "PermissionResponse")
               |> json_response(:created)

      assert %{"id" => new_permission_id, "name" => "#{@custom_prefix}permission_name"} = data

      assert %{"data" => data} =
               conn
               |> get(Routes.permission_path(conn, :show, new_permission_id))
               |> validate_resp_schema(schema, "PermissionResponse")
               |> json_response(:ok)

      assert %{"id" => ^new_permission_id, "name" => "#{@custom_prefix}permission_name"} = data
    end
  end

  describe "delete" do
    @tag authentication: [role: :user]
    test "non-admin user cannot delete permissions", %{conn: conn} do
      permission = insert(:permission)

      assert conn
             |> delete(Routes.permission_path(conn, :delete, permission))
             |> response(:forbidden)
    end

    @tag authentication: [role: :admin]
    test "deletes permission", %{conn: conn} do
      permission = insert(:permission)

      assert conn
             |> delete(Routes.permission_path(conn, :delete, permission))
             |> response(:no_content)

      assert_error_sent :not_found, fn ->
        get(conn, Routes.permission_path(conn, :show, permission))
      end
    end
  end
end
