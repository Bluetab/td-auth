defmodule TdAuthWeb.GroupControllerTest do
  use TdAuthWeb.ConnCase

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil}
  @create_user_attrs %{
    password: "some password_hash",
    user_name: "some user_name",
    is_admin: false,
    email: "some@email.com"
  }

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

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
      assert %{"data" => []} =
               conn
               |> get(Routes.group_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "create group" do
    @tag :admin_authenticated
    test "renders group when data is valid", %{conn: conn} do
      assert %{"data" => %{"id" => id}} =
               conn
               |> post(Routes.group_path(conn, :create), group: @create_attrs)
               |> json_response(:created)

      assert conn
             |> get(Routes.group_path(conn, :show, id))
             |> json_response(:ok)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.group_path(conn, :create), group: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end

    @tag :admin_authenticated
    test "renders errors when group is duplicated", %{conn: conn} do
      post(conn, Routes.group_path(conn, :create), group: @create_attrs)

      assert %{"errors" => %{} = errors} =
               conn
               |> post(Routes.group_path(conn, :create), group: @create_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end
  end

  describe "update group" do
    setup [:create_group]

    @tag :admin_authenticated
    test "renders group when data is valid", %{conn: conn, group: %Group{id: id} = group} do
      assert %{"data" => %{"id" => ^id}} =
               conn
               |> put(Routes.group_path(conn, :update, group), group: @update_attrs)
               |> json_response(:ok)

      assert conn
             |> get(Routes.group_path(conn, :show, id))
             |> json_response(:ok)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, group: group} do
      assert %{"errors" => %{} = errors} =
               conn
               |> put(Routes.group_path(conn, :update, group), group: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end
  end

  describe "delete group" do
    @tag :admin_authenticated
    test "deletes chosen group", %{conn: conn} do
      group = insert(:group)

      assert conn
             |> delete(Routes.group_path(conn, :delete, group))
             |> response(:no_content)

      assert_error_sent :not_found, fn -> get(conn, Routes.group_path(conn, :show, group)) end
    end
  end

  describe "create user groups" do
    @tag :admin_authenticated
    test "returns :created when data is valid", %{conn: conn} do
      %{id: user_id} = insert(:user)
      %{name: group_name} = insert(:group)

      assert conn
             |> post(Routes.user_group_path(conn, :add_groups_to_user, user_id),
               groups: [%{name: group_name}, %{name: "new group"}]
             )
             |> json_response(:created)
    end
  end

  describe "delete user group" do
    @tag :admin_authenticated
    test "deletes chosen group", %{conn: conn} do
      %{id: user_id, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])

      assert conn
             |> delete(Routes.user_group_path(conn, :delete_user_groups, user_id, group_id))
             |> response(:no_content)
    end
  end

  defp create_group(_) do
    group = fixture(:group)
    {:ok, group: group}
  end
end
