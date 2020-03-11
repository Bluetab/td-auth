defmodule TdAuthWeb.SessionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias Jason, as: JSON
  alias Phoenix.ConnTest
  alias TdAuth.Accounts
  alias TdAuth.Auth.Auth
  alias TdAuthWeb.ApiServices.MockAuthService
  alias TdCache.TaxonomyCache

  import TdAuthWeb.Authentication, only: :functions

  @create_attrs %{password: "temporal", user_name: "usuariotemporal", email: "some@email.com"}
  @valid_attrs %{password: "temporal", user_name: "usuariotemporal"}
  @invalid_attrs %{password: "invalido", user_name: "usuariotemporal"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup_all do
    start_supervised(MockAuthService)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create session " do
    setup [:create_user]

    test "create valid user session", %{conn: conn, swagger_schema: schema} do
      conn =
        post conn, Routes.session_path(conn, :create),
          access_method: "access_method",
          user: @valid_attrs

      validate_resp_schema(conn, schema, "Token")
      assert conn.status == 201
    end

    test "create session with claims", %{conn: conn, swagger_schema: schema, user: user} do
      permission_fixture(user)

      conn =
        post conn, Routes.session_path(conn, :create),
          access_method: "access_method",
          user: @valid_attrs

      token = json_response(conn, 201)["token"]
      assert {:ok, claims} = Auth.decode_and_verify(token, %{"typ" => "access"})

      assert claims["groups"] == [
               "create_permission_group",
               "view_permission_group",
               "update_permission_group"
             ]

      validate_resp_schema(conn, schema, "Token")
      assert conn.status == 201
    end

    test "create invalid user session", %{conn: conn} do
      conn =
        post conn, Routes.session_path(conn, :create),
          access_method: "access_method",
          user: @invalid_attrs

      assert conn.status == 401
    end
  end

  describe "create session with access token" do
    setup [:create_user]

    test "create valid non existing user session", %{conn: conn, swagger_schema: schema} do
      {:ok, jwt, _full_claims} = Auth.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)

      profile = %{
        nickname: "user_name",
        name: "name",
        family_name: "surname",
        email: "email@xyz.com"
      }

      MockAuthService.set_user_info(200, profile |> JSON.encode!())
      conn = post(conn, Routes.session_path(conn, :create))
      validate_resp_schema(conn, schema, "Token")
      assert conn.status == 201
      user = Accounts.get_user_by_name(profile[:nickname])
      assert user
      assert user.full_name == Enum.join([profile[:name], profile[:family_name]], " ")
      assert user.email == profile[:email]
    end

    test "create valid existing user session", %{conn: conn, swagger_schema: schema} do
      {:ok, jwt, _full_claims} = Auth.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)

      profile = %{
        nickname: "usueariotemporal",
        name: "Un nombre especial",
        family_name: "surname",
        email: "email@especial.com"
      }

      MockAuthService.set_user_info(200, profile |> JSON.encode!())
      conn = post(conn, Routes.session_path(conn, :create))
      validate_resp_schema(conn, schema, "Token")
      assert conn.status == 201
      user = Accounts.get_user_by_name(profile[:nickname])
      assert user
      assert user.full_name == Enum.join([profile[:name], profile[:family_name]], " ")
      assert user.email == profile[:email]
    end

    test "create invalid user session with access token", %{conn: conn} do
      {:ok, jwt, _full_claims} = Auth.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)
      profile = %{nickname: "user_name", name: "name", email: "email@xyz.com"}
      MockAuthService.set_user_info(401, profile |> JSON.encode!())
      conn = post(conn, Routes.session_path(conn, :create))
      assert conn.status == 401
      user = Accounts.get_user_by_name(profile[:nickname])
      assert !user
    end

    test "create session proxy login when not allowed", %{conn: conn} do
      Application.put_env(:td_auth, :allow_proxy_login, "false")
      conn = put_req_header(conn, "proxy-remote-user", "user_name")

      conn = post(conn, Routes.session_path(conn, :create))
      resp = json_response(conn, 401)

      assert resp == %{
               "errors" => %{
                 "code" => "proxy_login_disabled",
                 "detail" => "Proxy login is not enabled."
               }
             }
    end

    test "create session proxy login when is allowed and user is invalid", %{conn: conn} do
      Application.put_env(:td_auth, :allow_proxy_login, "true")
      conn = put_req_header(conn, "proxy-remote-user", "user_name")

      conn = post(conn, Routes.session_path(conn, :create))
      resp = json_response(conn, 401)
      assert resp == %{"errors" => %{"detail" => "Invalid credentials"}}
    end

    test "create session proxy login when is allowed and user is valid", %{conn: conn} do
      Application.put_env(:td_auth, :allow_proxy_login, "true")
      conn = put_req_header(conn, "proxy-remote-user", "usuariotemporal")

      conn = post(conn, Routes.session_path(conn, :create))
      assert conn.status == 201
    end
  end

  describe "refresh session" do
    setup [:create_user]

    test "refresh session with valid refresh token", %{conn: conn, swagger_schema: schema} do
      conn =
        post conn, Routes.session_path(conn, :create),
          access_method: "access_method",
          user: @valid_attrs

      validate_resp_schema(conn, schema, "Token")
      token_resp = json_response(conn, 201)
      token = token_resp["token"]
      refresh_token = token_resp["refresh_token"]

      assert token_resp["token"] != nil
      assert refresh_token != nil

      conn = ConnTest.recycle(conn)
      conn = put_auth_headers(conn, token)
      conn = post conn, Routes.session_path(conn, :refresh), %{refresh_token: refresh_token}
      validate_resp_schema(conn, schema, "Token")
      token_resp = json_response(conn, 201)
      token = token_resp["token"]
      assert token

      conn =
        conn
        |> ConnTest.recycle()
        |> put_auth_headers(token)

      conn = get(conn, Routes.session_path(conn, :ping))
      assert conn.status == 200
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end

  defp permission_fixture(user) do
    create_permission_group = insert(:permission_group, name: "create_permission_group")
    view_permission_group = insert(:permission_group, name: "view_permission_group")
    update_permission_group = insert(:permission_group, name: "update_permission_group")

    create = insert(:permission, name: "create", permission_group: create_permission_group)
    view = insert(:permission, name: "view", permission_group: view_permission_group)
    update = insert(:permission, name: "update", permission_group: update_permission_group)

    owner = insert(:role, name: "owner", permissions: [create])
    viewer = insert(:role, name: "viewer", permissions: [view])
    insert(:role, is_default: true, name: "default", permissions: [create, update])

    domain = %{id: :rand.uniform(1000), parent_ids: [], name: "MyDomain"}
    domain1 = %{id: domain.id + 1, parent_ids: [], name: "MyDomain1"}

    {:ok, _} = TaxonomyCache.put_domain(domain)
    {:ok, _} = TaxonomyCache.put_domain(domain1)

    insert(:acl_entry,
      resource_id: domain.id,
      principal_id: user.id,
      principal_type: "user",
      resource_type: "domain",
      role: owner
    )

    insert(:acl_entry,
      resource_id: domain1.id,
      principal_id: user.id,
      principal_type: "user",
      resource_type: "domain",
      role: viewer
    )
  end
end
