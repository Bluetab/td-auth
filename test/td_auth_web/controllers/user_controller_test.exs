defmodule TdAuthWeb.UserControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Guardian
  alias TdCache.TaxonomyCache

  import TdAuthWeb.Authentication, only: :functions

  @create_attrs %{
    password: "some password_hash",
    user_name: "some user_name",
    email: "some@email.com",
    groups: ["Group"]
  }
  @create_second_attrs %{
    password: "some password_hash",
    user_name: "some user_name 2"
  }
  @update_attrs %{
    password: "some updated password_hash",
    user_name: "some updated user_name",
    groups: ["GroupNew"]
  }
  @invalid_attrs %{password: nil, user_name: nil, email: nil}
  @valid_password "123456"
  @invalid_password ""

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  describe "GET /api/users" do
    @tag :admin_authenticated
    test "lists all users with role", %{
      conn: conn,
      swagger_schema: schema,
      user: %{user_name: user_name}
    } do
      assert %{"data" => data} =
               conn
               |> get(Routes.user_path(conn, :index))
               |> validate_resp_schema(schema, "UsersResponseData")
               |> json_response(:ok)

      assert [%{"user_name" => ^user_name, "role" => "admin"}] = data
    end

    @tag :admin_authenticated
    test "includes role in response", %{conn: conn, swagger_schema: schema} do
      insert(:user, role: "service")

      assert %{"data" => data} =
               conn
               |> get(Routes.user_path(conn, :index))
               |> validate_resp_schema(schema, "UsersResponseData")
               |> json_response(:ok)

      assert [%{"role" => "admin"}, %{"role" => "service"}] = data
    end

    test "non admin user lists all users if he has any permission in bg", %{conn: conn} do
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
                   "email" => ^email,
                   "full_name" => ^full_name,
                   "id" => ^user_id,
                   "role" => "user",
                   "user_name" => ^user_name
                 }
               ]
             } =
               conn
               |> put_auth_headers(token)
               |> get(Routes.user_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "POST /api/users" do
    @tag :authenticated_user
    test "returns forbidden for a non-admin user", %{conn: conn} do
      assert conn
             |> post(Routes.user_path(conn, :create), user: @create_second_attrs)
             |> response(:forbidden)
    end

    @tag :admin_authenticated
    test "renders user when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => id} = json_response(conn, :created)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => ^id, "user_name" => "some user_name"} = json_response(conn, 200)["data"]
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      validate_resp_schema(conn, schema, "UserResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "get user" do
    @tag :admin_authenticated
    test "renders user with configured acls", %{conn: conn, swagger_schema: schema} do
      domain = build(:domain)
      role = insert(:role)
      group = insert(:group)
      user = insert(:user, groups: [group])

      {:ok, _} = TaxonomyCache.put_domain(domain)

      insert(:acl_entry,
        user_id: user.id,
        principal_type: :user,
        resource_id: domain.id,
        resource_type: "domain",
        role: role
      )

      insert(:acl_entry,
        group_id: group.id,
        principal_type: :group,
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
    setup do
      [user: insert(:user)]
    end

    @tag :admin_authenticated
    test "renders user when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      user: %User{id: id} = user
    } do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))
      validate_resp_schema(conn, schema, "UserResponse")
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some updated user_name"
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, user: user} do
      assert %{"errors" => %{"email" => _, "user_name" => _}} =
               conn
               |> put(Routes.user_path(conn, :update, user), user: @invalid_attrs)
               |> json_response(422)
    end
  end

  describe "update password" do
    @tag :admin_authenticated
    test "ok when data is valid", %{conn: conn} do
      assert conn
             |> post(Routes.user_path(conn, :update_password), new_password: @valid_password)
             |> response(:no_content)
    end

    @tag :admin_authenticated
    test "error when data is invalid", %{conn: conn} do
      assert conn
             |> post(Routes.user_path(conn, :update_password), new_password: @invalid_password)
             |> response(:unprocessable_entity)
    end
  end

  describe "delete user" do
    setup do
      [user: insert(:user)]
    end

    @tag :admin_authenticated
    test "deletes chosen user", %{conn: conn, user: user} do
      assert conn
             |> delete(Routes.user_path(conn, :delete, user))
             |> response(204)

      assert_error_sent 404, fn -> get(conn, Routes.user_path(conn, :show, user)) end
    end
  end

  describe "init credential" do
    test "returns forbidden if exist users", %{conn: conn} do
      insert(:user)

      assert conn
             |> post(Routes.user_path(conn, :init), user: @create_attrs)
             |> response(:forbidden)
    end

    test "creates unprotected admin user if no protected users exist", %{
      conn: conn,
      swagger_schema: schema
    } do
      admin = insert(:user, is_protected: true, role: :admin)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_path(conn, :init), user: @create_attrs)
               |> validate_resp_schema(schema, "UserResponse")
               |> json_response(:created)

      assert %{"id" => id} = data

      assert %{"data" => data} =
               conn
               |> authenticate(admin)
               |> get(Routes.user_path(conn, :index))
               |> validate_resp_schema(schema, "UsersResponseData")
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end

    test "creates protected admin user if is_protected is specified", %{
      conn: conn,
      swagger_schema: schema
    } do
      admin = insert(:user, is_protected: true, role: :admin)

      params = %{user: Map.put(@create_attrs, :is_protected, true)}

      assert %{"data" => _} =
               conn
               |> post(Routes.user_path(conn, :init), params)
               |> validate_resp_schema(schema, "UserResponse")
               |> json_response(:created)

      assert %{"data" => []} =
               conn
               |> authenticate(admin)
               |> get(Routes.user_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "can init" do
    test "can init will return false if exist users", %{conn: conn} do
      insert(:user)

      assert conn
             |> get(Routes.user_path(conn, :can_init))
             |> response(:ok) == "false"
    end

    test "can init will return true if no users exist", %{conn: conn} do
      assert conn
             |> get(Routes.user_path(conn, :can_init))
             |> response(:ok) == "true"
    end
  end
end
