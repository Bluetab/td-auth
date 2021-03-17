defmodule TdAuthWeb.SessionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Accounts
  alias TdAuth.Auth.Guardian
  alias TdAuthWeb.ApiServices.MockAuth0Service
  alias TdCache.Redix
  alias TdCache.Redix.Stream
  alias TdCache.TaxonomyCache

  @stream TdCache.Audit.stream()

  @create_attrs %{password: "temporal", user_name: "usuariotemporal", email: "some@email.com"}
  @valid_attrs %{password: "temporal", user_name: "usuariotemporal"}
  @invalid_attrs %{password: "invalido", user_name: "usuariotemporal"}

  setup_all do
    on_exit(fn ->
      Redix.del!(@stream)
    end)
    start_supervised!(TdAuth.Accounts.UserLoader)
    start_supervised!(MockAuth0Service)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create session" do
    setup [:create_user]

    test "create valid user session", %{conn: conn, swagger_schema: schema} do
      Redix.del!(@stream)
      assert conn
             |> post(Routes.session_path(conn, :create),
               access_method: "access_method",
               user: @valid_attrs
             )
             |> validate_resp_schema(schema, "Token")
             |> response(:created)

      assert {:ok, [event_attempt, event_success]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{
        event: "login_attempt",
        payload: payload_attempt,
        resource_id: "",
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ""
      } = event_attempt

      assert %{
        "access_method" => "alternative_login",
        "user_name" => "usuariotemporal"
      } = Jason.decode!(payload_attempt)
      user_id = event_success.user_id

      assert %{
        event: "login_success",
        payload: payload_success,
        resource_id: ^user_id,
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ^user_id
      } = event_success

      assert %{
        "access_method" => "alternative_login",
        "user_name" => "usuariotemporal",
      } = Jason.decode!(payload_success)
    end

    test "create session with claims", %{conn: conn, swagger_schema: schema, user: user} do
      Redix.del!(@stream)
      permission_fixture(user)

      assert %{"token" => token} =
               conn
               |> post(Routes.session_path(conn, :create),
                 access_method: "access_method",
                 user: @valid_attrs
               )
               |> validate_resp_schema(schema, "Token")
               |> json_response(:created)

      assert {:ok, claims} = Guardian.decode_and_verify(token, %{"typ" => "access"})

      assert %{"role" => "user"} = claims
      assert_lists_equal(claims["groups"], ["create_pg", "view_pg", "update_pg"])

      assert {:ok, [event_attempt, event_success]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{
        event: "login_attempt",
        payload: payload_attempt,
        resource_id: "",
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ""
      } = event_attempt

      assert %{
        "access_method" => "alternative_login",
        "user_name" => "usuariotemporal",
      } = Jason.decode!(payload_attempt)
      user_id = event_success.user_id

      assert %{
        event: "login_success",
        payload: payload_success,
        resource_id: ^user_id,
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ^user_id
      } = event_success

      assert %{
        "access_method" => "alternative_login",
        "user_name" => "usuariotemporal",
      } = Jason.decode!(payload_success)
    end

    test "create invalid user session", %{conn: conn} do
      Redix.del!(@stream)
      assert conn
             |> post(Routes.session_path(conn, :create),
               access_method: "access_method",
               user: @invalid_attrs
             )
             |> response(:unauthorized)

      assert {:ok, [event]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{
        event: "login_attempt",
        payload: payload,
        resource_id: "",
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ""
      } = event

      assert %{
        "access_method" => "alternative_login",
        "user_name" => "usuariotemporal"
      } = Jason.decode!(payload)
    end
  end

  describe "create session with Auth0 access token" do
    setup [:create_user]

    test "create valid non existing user session", %{conn: conn, swagger_schema: schema} do
      Redix.del!(@stream)
      {:ok, jwt, _full_claims} = Guardian.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)

      profile = %{
        nickname: "user_name",
        name: "name",
        family_name: "surname",
        email: "email@xyz.com"
      }

      MockAuth0Service.set_user_info(200, Jason.encode!(profile))

      assert conn
             |> post(Routes.session_path(conn, :create), %{auth_realm: "auth0"})
             |> validate_resp_schema(schema, "Token")
             |> json_response(:created)

      user = Accounts.get_user_by_name(profile[:nickname])
      assert user
      assert user.full_name == Enum.join([profile[:name], profile[:family_name]], " ")
      assert user.email == profile[:email]

      assert {:ok, [event]} =
               Stream.read(:redix, @stream, transform: true)

      user_id = event.user_id

      assert %{
        event: "login_success",
        payload: payload,
        resource_id: ^user_id,
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ^user_id
      } = event

      assert %{
        "access_method" => nil,
        "user_name" => "user_name"
      } = Jason.decode!(payload)
    end

    test "create valid existing user session", %{conn: conn, swagger_schema: schema} do
      Redix.del!(@stream)
      {:ok, jwt, _full_claims} = Guardian.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)

      profile = %{
        nickname: "usuariotemporal",
        name: "Un nombre especial",
        family_name: "surname",
        email: "email@especial.com"
      }

      MockAuth0Service.set_user_info(200, Jason.encode!(profile))

      assert conn
             |> post(Routes.session_path(conn, :create), %{auth_realm: "auth0"})
             |> validate_resp_schema(schema, "Token")
             |> json_response(:created)

      user = Accounts.get_user_by_name(profile[:nickname])
      assert user
      assert user.full_name == Enum.join([profile[:name], profile[:family_name]], " ")
      assert user.email == profile[:email]

      assert {:ok, [event]} =
               Stream.read(:redix, @stream, transform: true)
      user_id = event.user_id

      assert %{
        event: "login_success",
        id: _id,
        payload: payload,
        resource_id: ^user_id,
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ^user_id
      } = event

      assert %{
        "access_method" => nil,
        "user_name" => "usuariotemporal"
      } = Jason.decode!(payload)
    end

    test "create invalid user session with access token", %{conn: conn} do
      Redix.del!(@stream)
      {:ok, jwt, _full_claims} = Guardian.encode_and_sign(nil)
      profile = %{nickname: "user_name", name: "name", email: "email@xyz.com"}
      MockAuth0Service.set_user_info(401, Jason.encode!(profile))

      assert conn
             |> put_auth_headers(jwt)
             |> post(Routes.session_path(conn, :create), %{auth_realm: "auth0"})
             |> response(:unauthorized)

      refute Accounts.get_user_by_name(profile[:nickname])

      assert {:ok, []} =
               Stream.read(:redix, @stream, transform: true)
    end

    test "create session proxy login when not allowed", %{conn: conn} do
      Redix.del!(@stream)
      Application.put_env(:td_auth, :allow_proxy_login, "false")

      assert %{"errors" => errors} =
               conn
               |> put_req_header("proxy-remote-user", "user_name")
               |> post(Routes.session_path(conn, :create))
               |> json_response(:unauthorized)

      assert %{"code" => "proxy_login_disabled"} = errors

      assert {:ok, []} =
               Stream.read(:redix, @stream, transform: true)
    end

    test "create session proxy login when is allowed and user is invalid", %{conn: conn} do
      Redix.del!(@stream)
      Application.put_env(:td_auth, :allow_proxy_login, "true")

      assert %{"errors" => errors} =
               conn
               |> put_req_header("proxy-remote-user", "user_name")
               |> post(Routes.session_path(conn, :create))
               |> json_response(:unauthorized)

      assert %{"detail" => "Invalid credentials"} = errors

      assert {:ok, []} =
               Stream.read(:redix, @stream, transform: true)
    end

    test "create session proxy login when is allowed and user is valid", %{conn: conn} do
      Redix.del!(@stream)
      Application.put_env(:td_auth, :allow_proxy_login, "true")

      assert conn
             |> put_req_header("proxy-remote-user", "usuariotemporal")
             |> post(Routes.session_path(conn, :create))
             |> json_response(:created)

      assert {:ok, [event]} =
               Stream.read(:redix, @stream, transform: true)

      user_id = event.user_id

      assert %{
        event: "login_success",
        id: _id,
        payload: payload,
        resource_id: ^user_id,
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ^user_id
      } = event

      assert %{
        "access_method" => "proxy_login",
        "user_name" => "usuariotemporal"
      } = Jason.decode!(payload)
    end
  end

  describe "refresh session" do
    setup [:create_user]

    test "refresh session with valid refresh token", %{conn: conn, swagger_schema: schema} do
      assert %{"token" => token, "refresh_token" => refresh_token} =
               conn
               |> post(Routes.session_path(conn, :create),
                 access_method: "access_method",
                 user: @valid_attrs
               )
               |> validate_resp_schema(schema, "Token")
               |> json_response(:created)

      assert %{"token" => token} =
               conn
               |> put_auth_headers(token)
               |> post(Routes.session_path(conn, :refresh), %{refresh_token: refresh_token})
               |> validate_resp_schema(schema, "Token")
               |> json_response(:created)

      assert conn
             |> put_auth_headers(token)
             |> get(Routes.session_path(conn, :ping))
             |> response(:ok)
    end
  end

  defp create_user(_) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    {:ok, user: user}
  end

  defp permission_fixture(user) do
    [create, view, update] =
      Enum.map(["create", "view", "update"], fn name ->
        insert(:permission,
          name: name,
          permission_group: build(:permission_group, name: "#{name}_pg")
        )
      end)

    owner = insert(:role, name: "owner", permissions: [create])
    viewer = insert(:role, name: "viewer", permissions: [view])
    insert(:role, is_default: true, name: "default", permissions: [create, update])

    Enum.each([owner, viewer], fn role ->
      domain = build(:domain)
      {:ok, _} = TaxonomyCache.put_domain(domain)

      insert(:acl_entry,
        resource_id: domain.id,
        user_id: user.id,
        principal_type: "user",
        resource_type: "domain",
        role: role
      )
    end)
  end
end
