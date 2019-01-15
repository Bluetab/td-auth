defmodule TdAuthWeb.GroupControllerTest do
  use TdAuthWeb.ConnCase

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  import TdAuthWeb.Authentication, only: :functions

  @create_attrs %{name: "some name", description: "some description"}
  @create_attrs2 %{name: "some name2", description: "some description2"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil}
  @create_user_attrs %{
    password: "some password_hash",
    user_name: "some user_name",
    is_admin: false,
    email: "some@email.com"
  }

  def fixture(:group) do
    {:ok, group} = Accounts.create_group(@create_attrs)
    group
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_user_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all groups", %{conn: conn} do
      conn = get(conn, Routes.group_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create group" do
    @tag :admin_authenticated
    test "renders group when data is valid", %{conn: conn} do
      conn = post conn, Routes.group_path(conn, :create), group: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      conn = recycle_and_put_headers(conn)
      conn = get(conn, Routes.group_path(conn, :show, id))
      assert json_response(conn, 200)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.group_path(conn, :create), group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag :admin_authenticated
    test "renders errors when group is duplicated", %{conn: conn} do
      conn = post conn, Routes.group_path(conn, :create), group: @create_attrs
      conn = recycle_and_put_headers(conn)
      conn = post conn, Routes.group_path(conn, :create), group: @create_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update group" do
    setup [:create_group]

    @tag :admin_authenticated
    test "renders group when data is valid", %{conn: conn, group: %Group{id: id} = group} do
      conn = put conn, Routes.group_path(conn, :update, group), group: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
      conn = recycle_and_put_headers(conn)
      conn = get(conn, Routes.group_path(conn, :show, id))
      assert json_response(conn, 200)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, group: group} do
      conn = put conn, Routes.group_path(conn, :update, group), group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete group" do
    setup [:create_group]

    @tag :admin_authenticated
    test "deletes chosen group", %{conn: conn, group: group} do
      conn = delete(conn, Routes.group_path(conn, :delete, group))
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get(conn, Routes.group_path(conn, :show, group))
      end
    end
  end

  describe "create user groups" do
    setup [:create_group]
    setup [:create_user]

    @tag :admin_authenticated
    test "renders user groups when data is valid", %{conn: conn, user: %User{id: user_id}} do
      conn =
        post conn, Routes.user_group_path(conn, :add_groups_to_user, user_id),
          groups: [@create_attrs, @create_attrs2]

      assert json_response(conn, 201)
    end
  end

  describe "delete user group" do
    setup [:create_group]
    setup [:create_user]

    @tag :admin_authenticated
    test "deletes chosen group", %{
      conn: conn,
      user: %User{id: user_id} = group,
      group: %Group{id: group_id}
    } do
      conn =
        post conn, Routes.user_group_path(conn, :add_groups_to_user, user_id),
          groups: [@create_attrs, @create_attrs2]

      assert json_response(conn, 201)
      conn = recycle_and_put_headers(conn)
      conn = delete(conn, Routes.user_group_path(conn, :delete_user_groups, user_id, group_id))
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get(conn, Routes.group_path(conn, :show, group))
      end
    end
  end

  defp create_group(_) do
    group = fixture(:group)
    {:ok, group: group}
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
