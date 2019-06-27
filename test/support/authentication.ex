defmodule TdAuthWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """

  import Plug.Conn

  alias Jason, as: JSON
  alias Phoenix.ConnTest
  alias TdAuth.Accounts
  alias TdAuth.Auth.Guardian
  alias TdAuthWeb.Router.Helpers, as: Routes

  @endpoint TdAuthWeb.Endpoint
  @headers {"Content-type", "application/json"}

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def recycle_and_put_headers(conn) do
    authorization_header = List.first(get_req_header(conn, "authorization"))

    conn
    |> ConnTest.recycle()
    |> put_req_header("authorization", authorization_header)
  end

  def create_user_auth_conn(user) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)
    conn = ConnTest.build_conn()
    conn = put_auth_headers(conn, jwt)
    {:ok, %{conn: conn, jwt: jwt, claims: full_claims}}
  end

  def create_user_auth_conn(conn, user_name) do
    user = Accounts.get_user_by_name(user_name)
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)
    conn = put_auth_headers(conn, jwt)
    {:ok, %{conn: conn, jwt: jwt, claims: full_claims}}
  end

  def get_default_headers do
    [@headers]
  end

  def get_jwt_headers(token) do
    [@headers, {"authorization", "Bearer #{token}"}]
  end

  def session_create(user_name, user_password) do
    body =
      %{user: %{user_name: user_name, password: user_password}, access_method: nil}
      |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.session_url(@endpoint, :create), body, [@headers], [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def session_destroy(token) do
    headers = get_jwt_headers(token)

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(Routes.session_url(@endpoint, :destroy), headers, [])

    {:ok, status_code}
  end
end
