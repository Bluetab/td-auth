defmodule TdAuthWeb.GroupControllerTest do
  use TdAuthWeb.ConnCase

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Auth.Guardian

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil}
  @create_user_attrs %{
    password: "some password_hash",
    user_name: "some user_name",
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
      %{id: user_id, email: email, full_name: full_name, user_name: user_name} =
        user = insert(:user)

      %{id: group_id, name: name, description: description} = insert(:group, users: [user])

      assert %{
               "data" => [
                 %{
                   "description" => ^description,
                   "id" => ^group_id,
                   "name" => ^name,
                   "users" => [
                     %{
                       "email" => ^email,
                       "full_name" => ^full_name,
                       "id" => ^user_id,
                       "role" => "user",
                       "user_name" => ^user_name
                     }
                   ]
                 }
               ]
             } =
               conn
               |> get(Routes.group_path(conn, :index))
               |> json_response(:ok)
    end

    test "non admin user lists all groups if he has any permission in bg", %{conn: conn} do
      {:ok, %{id: user_id, email: email, full_name: full_name, user_name: user_name} = user} =
        :user
        |> build(password: "pass000")
        |> Map.take([:user_name, :password, :email])
        |> Accounts.create_user()

      group = insert(:permission_group, name: "business_glossary_view")
      permission = insert(:permission, permission_group: group)
      role = insert(:role, permissions: [permission])

      insert(:acl_entry,
        user: user,
        role: role,
        principal_type: "user",
        resource_type: "domain",
        group: nil,
        group_id: nil
      )

      %{id: group_id, name: name, description: description} = insert(:group, users: [user])

      assert %{"token" => token} =
               conn
               |> post(Routes.session_path(conn, :create),
                 access_method: "access_method",
                 user: Map.take(user, [:user_name, :password])
               )
               |> json_response(:created)

      assert {:ok, %{"groups" => ["business_glossary_view"]}} =
               Guardian.decode_and_verify(token, %{"typ" => "access"})

      assert %{
               "data" => [
                 %{
                   "description" => ^description,
                   "id" => ^group_id,
                   "name" => ^name,
                   "users" => [
                     %{
                       "email" => ^email,
                       "full_name" => ^full_name,
                       "id" => ^user_id,
                       "role" => "user",
                       "user_name" => ^user_name
                     }
                   ]
                 }
               ]
             } =
               conn
               |> put_auth_headers(token)
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

  defp create_group(_) do
    group = fixture(:group)
    {:ok, group: group}
  end
end
