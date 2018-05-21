defmodule TdAuthWeb.SessionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.Accounts
  alias Phoenix.ConnTest

  alias TdAuthWeb.ApiServices.MockAuthService
  alias Poison, as: JSON

  alias TdAuth.Auth.Auth

  import TdAuthWeb.Authentication, only: :functions

  @create_attrs %{password: "temporal",
                 user_name: "usuariotemporal",
                 email: "some@email.com"}
  @valid_attrs %{password: "temporal",
                 user_name: "usuariotemporal"}
  @invalid_attrs %{password: "invalido",
                 user_name: "usuariotemporal"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup_all do
    start_supervised MockAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create session " do
    setup [:create_user]

    test "create valid user session", %{conn: conn, swagger_schema: schema} do
      conn = post conn, session_path(conn, :create), user: @valid_attrs
      validate_resp_schema(conn, schema, "Token")
      assert conn.status ==  201
    end

    test "create invalid user session", %{conn: conn} do
      conn = post conn, session_path(conn, :create), user: @invalid_attrs
      assert conn.status ==  401
    end

  end

  describe "create session with access token" do
    setup [:create_user]

    test "create valid non existing user session", %{conn: conn, swagger_schema: schema} do
      {:ok, jwt, _full_claims} = Auth.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)
      profile = %{nickname: "user_name", name: "name", email: "email@xyz.com"}
      MockAuthService.set_user_info(200, profile |> JSON.encode!)
      conn = post conn, session_path(conn, :create)
      validate_resp_schema(conn, schema, "Token")
      assert conn.status ==  201
      user = Accounts.get_user_by_name(profile[:nickname])
      assert user
      assert user.full_name == profile[:name]
      assert user.email == profile[:email]
    end

    test "create valid existing user session", %{conn: conn, swagger_schema: schema} do
      {:ok, jwt, _full_claims} = Auth.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)
      profile = %{nickname: "usueariotemporal", name: "Un nombre especial", email: "email@especial.com"}
      MockAuthService.set_user_info(200, profile |> JSON.encode!)
      conn = post conn, session_path(conn, :create)
      validate_resp_schema(conn, schema, "Token")
      assert conn.status ==  201
      user = Accounts.get_user_by_name(profile[:nickname])
      assert user
      assert user.full_name == profile[:name]
      assert user.email == profile[:email]
    end

    test "create invalid user session with access token", %{conn: conn} do
      {:ok, jwt, _full_claims} = Auth.encode_and_sign(nil)
      conn = put_auth_headers(conn, jwt)
      profile = %{nickname: "user_name", name: "name", email: "email@xyz.com"}
      MockAuthService.set_user_info(401, profile |> JSON.encode!)
      conn = post conn, session_path(conn, :create)
      assert conn.status ==  401
      user = Accounts.get_user_by_name(profile[:nickname])
      assert !user
    end

  end

  describe "refresh session" do
    setup [:create_user]

    test "refresh session with valid refresh token", %{conn: conn, swagger_schema: schema} do
      conn = post conn, session_path(conn, :create), user: @valid_attrs
      validate_resp_schema(conn, schema, "Token")
      token_resp = json_response(conn, 201)
      token = token_resp["token"]
      refresh_token = token_resp["refresh_token"]

      assert token_resp["token"] != nil
      assert refresh_token != nil

      conn = ConnTest.recycle(conn)
      conn = put_auth_headers(conn, token)
      conn = post conn, session_path(conn, :refresh), %{refresh_token: refresh_token}
      validate_resp_schema(conn, schema, "Token")
      token_resp = json_response(conn, 201)
      token = token_resp["token"]
      assert token

      conn = conn
      |> ConnTest.recycle
      |> put_auth_headers(token)

      conn = get conn, session_path(conn, :ping)
      assert conn.status == 200
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
