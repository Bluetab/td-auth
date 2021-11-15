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
    external_id: "some external_id",
    email: "some@email.com",
    groups: ["Group"]
  }
  @create_second_attrs %{
    password: "some password_hash",
    user_name: "some user_name 2"
  }
  @update_attrs %{
    user_name: "some updated user_name",
    external_id: "some updated external_id",
    groups: ["GroupNew"]
  }
  @invalid_attrs %{user_name: nil, email: nil}
  @attrs_with_passw %{password: "123456"}

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  describe "GET /api/users" do
    @tag authentication: [role: :admin]
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

    @tag authentication: [role: :admin]
    test "includes role in response", %{conn: conn, swagger_schema: schema} do
      insert(:user, role: "service")

      assert %{"data" => data} =
               conn
               |> get(Routes.user_path(conn, :index))
               |> validate_resp_schema(schema, "UsersResponseData")
               |> json_response(:ok)

      assert [%{"role" => "admin"}, %{"role" => "service"}] = data
    end

    @tag authentication: [role: :admin]
    test "includes external_id in response", %{conn: conn, swagger_schema: schema} do
      insert(:user, external_id: "foo")

      assert %{"data" => data} =
               conn
               |> get(Routes.user_path(conn, :index))
               |> validate_resp_schema(schema, "UsersResponseData")
               |> json_response(:ok)

      assert Enum.find(data, fn user -> Map.get(user, "external_id") == "foo" end)
    end

    @tag authentication: [role: :service]
    test "service account can view users", %{conn: conn} do
      assert %{"data" => [_]} =
               conn
               |> get(Routes.user_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: :user]
    test "user account cannot view users", %{conn: conn} do
      assert %{"errors" => _} =
               conn
               |> get(Routes.user_path(conn, :index))
               |> json_response(:forbidden)
    end

    test "user account cannot list all users even having any permission in bg", %{conn: conn} do
      {:ok, user} =
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

      assert conn
             |> put_auth_headers(token)
             |> get(Routes.user_path(conn, :index))
             |> json_response(:forbidden)
    end
  end

  describe "POST /api/users" do
    @tag authentication: [role: :user]
    test "returns forbidden for a non-admin user", %{conn: conn} do
      assert conn
             |> post(Routes.user_path(conn, :create), user: @create_second_attrs)
             |> response(:forbidden)
    end

    @tag authentication: [role: :admin]
    test "renders user when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => id} = json_response(conn, :created)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => ^id, "user_name" => "some user_name"} = json_response(conn, :ok)["data"]
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      validate_resp_schema(conn, schema, "UserResponse")
      assert json_response(conn, :unprocessable_entity)["errors"] != %{}
    end
  end

  describe "get user" do
    @tag authentication: [role: :admin]
    test "renders user with configured acls", %{conn: conn, swagger_schema: schema} do
      domain = build(:domain)
      role = insert(:role)
      group = insert(:group)
      user = insert(:user, external_id: "get external_id", groups: [group])

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
      user_data = json_response(conn, :ok)["data"]
      assert user_data["external_id"] == user.external_id
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

    @tag authentication: [role: :admin]
    test "renders user when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      user: %User{id: id} = user
    } do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      validate_resp_schema(conn, schema, "UserResponse")
      assert %{"id" => ^id} = json_response(conn, :ok)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))
      validate_resp_schema(conn, schema, "UserResponse")
      user_data = json_response(conn, :ok)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some updated user_name"
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn, user: user} do
      assert %{"errors" => %{"user_name" => _}} =
               conn
               |> put(Routes.user_path(conn, :update, user), user: @invalid_attrs)
               |> json_response(:unprocessable_entity)
    end

    @tag authentication: [role: :admin]
    test "renders errors when try to update password on users update", %{conn: conn, user: user} do
      assert %{"errors" => %{"detail" => "Forbidden"}} =
               conn
               |> put(Routes.user_path(conn, :update, user), user: @attrs_with_passw)
               |> json_response(:forbidden)
    end
  end

  describe "delete user" do
    setup do
      [user: insert(:user)]
    end

    @tag authentication: [role: :admin]
    test "deletes chosen user", %{conn: conn, user: user} do
      assert conn
             |> delete(Routes.user_path(conn, :delete, user))
             |> response(:no_content)

      assert_error_sent :not_found, fn -> get(conn, Routes.user_path(conn, :show, user)) end
    end
  end

  describe "init credential" do
    test "returns forbidden if exist admin users", %{conn: conn} do
      insert(:user, role: :admin)

      assert conn
             |> post(Routes.user_path(conn, :init), user: @create_attrs)
             |> response(:forbidden)
    end

    test "creates admin user if neither admin nor user role users exist", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{id: admin_id} = admin = insert(:user, role: :service)

      assert %{"data" => user} =
               conn
               |> post(Routes.user_path(conn, :init), user: @create_attrs)
               |> validate_resp_schema(schema, "UserResponse")
               |> json_response(:created)

      assert %{"id" => id} = user

      assert %{"data" => data} =
               conn
               |> authenticate(admin)
               |> get(Routes.user_path(conn, :index))
               |> validate_resp_schema(schema, "UsersResponseData")
               |> json_response(:ok)

      ids = Enum.map(data, &Map.get(&1, "id"))
      assert Enum.all?([id, admin_id], &(&1 in ids))
    end
  end

  describe "can init" do
    test "can init will return false if exist admin users", %{conn: conn} do
      insert(:user, role: :admin)

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
