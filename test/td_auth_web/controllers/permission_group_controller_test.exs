defmodule TdAuthWeb.PermissionGroupControllerTest do
  use TdAuthWeb.ConnCase

  alias TdAuth.Permissions.PermissionGroup

  @invalid_attrs %{name: nil}
  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)
  @create_attrs %{name: "#{@custom_prefix}group name"}
  @update_attrs %{name: "#{@custom_prefix}new_group_name"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: :admin]
    test "lists all permission_groups", %{conn: conn} do
      expected =
        1..5
        |> Enum.map(fn _ -> insert(:permission_group) end)
        |> Enum.map(fn %{id: id, name: name} -> %{"id" => id, "name" => name} end)

      assert %{"data" => data} =
               conn
               |> get(Routes.permission_group_path(conn, :index))
               |> json_response(200)

      assert_lists_equal(
        data,
        expected,
        &assert_maps_equal(&1, &2, ["id", "name"])
      )
    end
  end

  describe "create permission_group" do
    @tag authentication: [role: :admin]
    test "renders permission_group when data is valid", %{conn: conn} do
      assert %{"data" => data} =
               conn
               |> post(Routes.permission_group_path(conn, :create),
                 permission_group: @create_attrs
               )
               |> json_response(:created)

      assert %{"id" => _id} = data
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.permission_group_path(conn, :create),
                 permission_group: @invalid_attrs
               )
               |> json_response(:unprocessable_entity)

      assert errors == %{"name" => ["can't be blank"]}
    end

    @tag authentication: [role: :admin]
    test "renders errors if non-custom group is created", %{
      conn: conn
    } do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.permission_group_path(conn, :create),
                 permission_group: %{name: "non_custom_name"}
               )
               |> json_response(:unprocessable_entity)

      assert errors == %{
               "name" => [
                 "External permission group creation requires a name starting with '#{@custom_prefix}'"
               ]
             }
    end
  end

  describe "update permission_group" do
    setup :create_permission_group

    @tag authentication: [role: :admin]
    test "renders permission_group when data is valid", %{
      conn: conn,
      permission_group: %PermissionGroup{id: id} = permission_group
    } do
      assert %{"data" => data} =
               conn
               |> put(Routes.permission_group_path(conn, :update, permission_group),
                 permission_group: @update_attrs
               )
               |> json_response(:ok)

      assert %{"id" => ^id} = data
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn, permission_group: permission_group} do
      conn =
        put(conn, Routes.permission_group_path(conn, :update, permission_group),
          permission_group: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: :admin]
    test "renders errors if non-custom group is created", %{
      conn: conn,
      permission_group: permission_group
    } do
      assert %{"errors" => errors} =
               put(conn, Routes.permission_group_path(conn, :update, permission_group),
                 permission_group: %{name: "changed_non_custom_name"}
               )
               |> json_response(:unprocessable_entity)

      assert errors == %{
               "name" => [
                 "External permission group creation requires a name starting with '#{@custom_prefix}'"
               ]
             }
    end
  end

  describe "delete permission_group" do
    setup :create_permission_group

    @tag authentication: [role: :admin]
    test "deletes chosen permission_group", %{conn: conn, permission_group: permission_group} do
      conn = delete(conn, Routes.permission_group_path(conn, :delete, permission_group))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.permission_group_path(conn, :show, permission_group))
      end
    end
  end

  defp create_permission_group(_) do
    permission_group = insert(:permission_group)
    {:ok, permission_group: permission_group}
  end
end
