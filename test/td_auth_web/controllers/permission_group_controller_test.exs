defmodule TdAuthWeb.PermissionGroupControllerTest do
  use TdAuthWeb.ConnCase

  alias TdAuth.Permissions.PermissionGroup

  @create_attrs %{name: "group name"}
  @update_attrs %{name: "new group name"}
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all permission_groups", %{conn: conn} do
      conn = get(conn, Routes.permission_group_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create permission_group" do
    @tag :admin_authenticated
    test "renders permission_group when data is valid", %{conn: conn} do
      conn = post(conn, Routes.permission_group_path(conn, :create), permission_group: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.permission_group_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.permission_group_path(conn, :create), permission_group: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update permission_group" do
    setup [:create_permission_group]

    @tag :admin_authenticated
    test "renders permission_group when data is valid", %{conn: conn, permission_group: %PermissionGroup{id: id} = permission_group} do
      conn = put(conn, Routes.permission_group_path(conn, :update, permission_group), permission_group: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.permission_group_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, permission_group: permission_group} do
      conn = put(conn, Routes.permission_group_path(conn, :update, permission_group), permission_group: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete permission_group" do
    setup [:create_permission_group]

    @tag :admin_authenticated
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
