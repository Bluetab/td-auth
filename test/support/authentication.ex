defmodule TdAuthWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """

  import Plug.Conn

  alias Phoenix.ConnTest
  alias TdAuth.Auth.Guardian
  alias TdAuthWeb.Router.Helpers, as: Routes

  @endpoint TdAuthWeb.Endpoint
  @headers {"content-type", "application/json"}

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def authenticate(conn, user) do
    {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, Map.take(user, [:role]))
    put_auth_headers(conn, jwt)
  end

  def create_user_auth_conn(user) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user, Map.take(user, [:role]))
    {:ok, claims} = Guardian.resource_from_claims(full_claims)

    conn =
      ConnTest.build_conn()
      |> put_auth_headers(jwt)

    {:ok, %{conn: conn, jwt: jwt, user: user, claims: claims}}
  end

  def get_default_headers do
    [@headers]
  end

  def get_jwt_headers(token) do
    [@headers, {"authorization", "Bearer #{token}"}]
  end

  def session_create(user_name, user_password) do
    body =
      %{user: %{user_name: user_name, password: user_password}}
      |> Jason.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.session_url(@endpoint, :create), body, [@headers], [])

    {:ok, status_code, Jason.decode!(resp)}
  end

  def session_destroy(token) do
    headers = get_jwt_headers(token)

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(Routes.session_url(@endpoint, :destroy), headers, [])

    {:ok, status_code}
  end
end
