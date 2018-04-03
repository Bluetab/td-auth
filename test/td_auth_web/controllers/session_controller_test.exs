defmodule TdAuthWeb.SessionControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.Accounts
  alias Phoenix.ConnTest

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

  describe "refresh session" do
    setup [:create_user]

    test "refresh session with valid refresh token", %{conn: conn, swagger_schema: schema} do
      conn = post conn, session_path(conn, :create), user: @valid_attrs
      validate_resp_schema(conn, schema, "Token")
      token_resp = json_response(conn, 201)
      refresh_token = token_resp["refresh_token"]

      assert token_resp["token"] != nil
      assert refresh_token != nil

      conn = ConnTest.recycle(conn)
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
