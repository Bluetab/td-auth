defmodule TdAuthWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """

  import Plug.Conn

  alias Phoenix.ConnTest
  alias TdAuth.Sessions

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def authenticate(conn, user) do
    {:ok, %{token: jwt}} = Sessions.create(user, "pwd")

    put_auth_headers(conn, jwt)
  end

  def create_user_auth_conn(user) do
    {:ok, %{token: jwt, claims: claims}} = Sessions.create(user, "pwd")

    conn =
      ConnTest.build_conn()
      |> put_auth_headers(jwt)

    {:ok, %{conn: conn, jwt: jwt, user: user, claims: claims}}
  end

  def assign_permissions(state, permissions, domain_params \\ %{})

  def assign_permissions({:ok, %{claims: claims} = state}, [_ | _] = permissions, domain_params) do
    %{id: domain_id} = domain = TdAuth.CacheHelpers.put_domain(domain_params || %{})
    TdAuth.CacheHelpers.put_session_permissions(claims, domain_id, permissions)
    {:ok, Map.put(state, :domain, domain)}
  end

  def assign_permissions(state, _, _), do: state
end
