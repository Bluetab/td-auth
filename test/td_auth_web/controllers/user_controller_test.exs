defmodule TdAuthWeb.UserControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdPerms.TaxonomyCache

  @create_attrs %{
    password: "some password_hash",
    user_name: "some user_name",
    is_admin: false,
    email: "some@email.com",
    groups: ["Group"]
  }
  @create_second_attrs %{
    password: "some password_hash",
    user_name: "some user_name 2",
    is_admin: false
  }
  @update_attrs %{
    password: "some updated password_hash",
    user_name: "some updated user_name",
    groups: ["GroupNew"]
  }
  @update_is_admin %{user_name: "some updated user_name", is_admin: true}
  @invalid_attrs %{password: nil, user_name: nil, email: nil}
  @admin_user_name "app-admin"

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  describe "index with authenticated user tag" do
    @tag :admin_authenticated
    test "list all users with some user name", %{conn: conn, jwt: _jwt, swagger_schema: schema} do
      conn = get(conn, Routes.user_path(conn, :index))
      validate_resp_schema(conn, schema, "UsersResponseData")
      [admin_user | _tail] = json_response(conn, 200)["data"]
      assert admin_user["user_name"] == @admin_user_name
    end
  end

  describe "index" do
    @tag :admin_authenticated
    test "list all users", %{conn: conn, jwt: _jwt, swagger_schema: schema} do
      conn = get(conn, Routes.user_path(conn, :index))
      validate_resp_schema(conn, schema, "UsersResponseData")
      [admin_user | _tail] = json_response(conn, 200)["data"]
      assert admin_user["user_name"] == @admin_user_name
    end
  end

  describe "try to create user by a non admin" do
    setup [:create_user]

    test "create user with a non admin user renders error", %{conn: conn} do
      {:ok, %{conn: conn, jwt: _jwt, claims: _full_claims}} =
        create_user_auth_conn(conn, @create_attrs.user_name)

      conn = post conn, Routes.user_path(conn, :create), user: @create_second_attrs
      assert response(conn, 403)
    end
  end

  describe "create user" do
    @tag :admin_authenticated
    test "renders user when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, Routes.user_path(conn, :create), user: @create_attrs
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get(conn, Routes.user_path(conn, :show, id))
      validate_resp_schema(conn, schema, "UserResponse")
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some user_name"
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: _jwt, swagger_schema: schema} do
      conn = post conn, Routes.user_path(conn, :create), user: @invalid_attrs
      validate_resp_schema(conn, schema, "UserResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "get user" do
    @tag :admin_authenticated
    test "renders user with configured acls", %{conn: conn, swagger_schema: schema} do
      domain = %{id: :rand.uniform(1000), parent_ids: [], name: "MyDomain"}
      role = insert(:role)
      group = insert(:group)
      user = insert(:user, groups: [group])

      {:ok, _} = TaxonomyCache.put_domain(domain)

      insert(:acl_entry,
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain.id,
        resource_type: "domain",
        role: role
      )

      insert(:acl_entry,
        principal_id: group.id,
        principal_type: "group",
        resource_id: domain.id,
        resource_type: "domain",
        role: role
      )

      conn = get(conn, Routes.user_path(conn, :show, user.id))
      validate_resp_schema(conn, schema, "UserResponse")
      user_data = json_response(conn, 200)["data"]
      assert Map.has_key?(user_data, "acls")
      acls = Map.get(user_data, "acls")
      assert length(acls) == 2
      acl = Enum.find(acls, &(!Map.has_key?(&1, "group")))
      group_acl = Enum.find(acls, &Map.has_key?(&1, "group"))

      assert acl["resource"]["name"] == domain.name
      assert acl["role"]["name"] == role.name

      assert group_acl["resource"]["name"] == domain.name
      assert group_acl["role"]["name"] == role.name
      assert group_acl["group"]["name"] == group.name
    end
  end

  describe "update user" do
    setup [:create_user]

    @tag :admin_authenticated
    test "renders user when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      user: %User{id: id} = user
    } do
      conn = put conn, Routes.user_path(conn, :update, user), user: @update_attrs
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get(conn, Routes.user_path(conn, :show, id))
      validate_resp_schema(conn, schema, "UserResponse")
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some updated user_name"
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: _jwt, user: user} do
      conn = put conn, Routes.user_path(conn, :update, user), user: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag :admin_authenticated
    test "update user is admin flag", %{conn: conn, swagger_schema: schema, jwt: _jwt, user: user} do
      conn = put conn, Routes.user_path(conn, :update, user), user: @update_is_admin
      validate_resp_schema(conn, schema, "UserResponse")
      updated_user = json_response(conn, 200)["data"]
      persisted_user = Accounts.get_user_by_name(updated_user["user_name"])
      assert persisted_user.is_admin == @update_is_admin.is_admin
    end
  end

  describe "delete user" do
    setup [:create_user]

    @tag :admin_authenticated
    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 204)

      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  describe "init credential" do
    test "init credential will fail if exist users", %{conn: conn} do
      fixture(:user)
      conn = post conn, Routes.user_path(conn, :init), user: @create_attrs
      assert conn.status == 403
    end

    test "init credential will render a randomly generated user", %{
      conn: conn,
      swagger_schema: schema
    } do
      conn = post conn, Routes.user_path(conn, :init), user: @create_attrs
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
