defmodule TdAuthWeb.SessionController do
  use TdAuthWeb, :controller

  alias Plug.Conn.Cookies
  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.AuditAuth
  alias TdAuth.Ldap.Ldap
  alias TdAuth.Saml.SamlWorker
  alias TdAuth.Sessions
  alias TdAuthWeb.AuthProvider.ActiveDirectory
  alias TdAuthWeb.AuthProvider.Auth0
  alias TdAuthWeb.AuthProvider.OIDC
  alias TdAuthWeb.ErrorView

  alias TdCache.NonceCache

  require Logger

  def create(conn, %{"SAMLResponse" => _} = params) do
    nonce =
      params
      |> Jason.encode!()
      |> NonceCache.create_nonce()

    redirect(conn, to: "/saml#nonce=#{nonce}")
  end

  def create(
        conn,
        %{
          "auth_realm" => "active_directory",
          "user" => %{"user_name" => user_name, "password" => password}
        } = params
      ) do
    {:ok, _} = AuditAuth.attempt_event("active_directory", params)
    authenticate_using_active_directory_and_create_session(conn, user_name, password)
  end

  def create(
        conn,
        %{
          "auth_realm" => "ldap",
          "user" => %{"user_name" => user_name, "password" => password}
        } = params
      ) do
    {:ok, _} = AuditAuth.attempt_event("ldap", params)
    authenticate_using_ldap_and_create_session(conn, user_name, password)
  end

  def create(conn, %{"auth_realm" => "oidc", "code" => code} = params) when is_binary(code) do
    authenticate_using_oidc_and_create_session(conn, params)
  end

  def create(conn, %{"auth_realm" => "oidc"}) do
    authenticate_using_oidc_and_create_session(conn)
  end

  def create(conn, %{"auth_realm" => "auth0"} = params) do
    authenticate_using_auth0_and_create_session(conn, params)
  end

  def create(conn, %{"auth_realm" => auth_realm, "nonce" => nonce}) do
    case NonceCache.pop(nonce) do
      nil -> unauthorized(conn)
      json -> create_nonce_session(conn, auth_realm, json)
    end
  end

  def create(conn, %{"user" => %{"user_name" => user_name, "password" => password}} = params) do
    {:ok, _} = AuditAuth.attempt_event("pwd", params)
    authenticate_and_create_session(conn, user_name, password, "pwd")
  end

  def create(%{req_headers: headers} = conn, params) do
    create(conn, Map.new(headers), params)
  end

  def create(conn, _params) do
    create(conn, nil, nil)
  end

  defp create(conn, %{"proxy-remote-user" => user_name}, _params) do
    allow_proxy_login = Application.get_env(:td_auth, :allow_proxy_login)
    authenticate_proxy_login(conn, user_name, allow_proxy_login)
  end

  defp create(conn, _headers, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ErrorView)
    |> render("422.json")
  end

  defp create_session(conn, user, access_method) do
    {:ok, %{token: token, refresh_token: refresh_token}} = Sessions.create(user, access_method)
    {:ok, _} = AuditAuth.session_event(access_method, user)

    conn
    |> put_refresh_token(refresh_token)
    |> put_status(:created)
    |> render("show.json", token: token)
  end

  def create_nonce_session(conn, "saml", json) do
    params = Jason.decode!(json)

    [saml_response, saml_encoding] =
      ["SAMLResponse", "SAMLEncoding"]
      |> Enum.map(&Map.get(params, &1))

    authenticate_using_saml_and_create_session(conn, saml_response, saml_encoding)
  end

  def create_nonce_session(conn, _, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ErrorView)
    |> render("422.json")
  end

  defp authenticate_using_saml_and_create_session(conn, saml_response, saml_encoding) do
    with {:ok, profile} <- SamlWorker.validate(saml_response, saml_encoding),
         {:ok, user} <- Accounts.create_or_update_user(profile, true) do
      create_session(conn, user, "fed")
    else
      error ->
        Logger.info("While authenticating using SAML ... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_active_directory_and_create_session(conn, user_name, password) do
    with {:ok, profile} <- ActiveDirectory.authenticate(user_name, password),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, "ad")
    else
      error ->
        Logger.info("While authenticating using active directory ... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_ldap_and_create_session(conn, user_name, password) do
    with {:ok, profile, validation_warnings} <- Ldap.authenticate(user_name, password),
         {:ok, user} <- Accounts.create_or_update_user(profile),
         {:ok, %{token: access_token, refresh_token: refresh_token}} <-
           Sessions.create(user, "ldap") do
      conn
      |> put_refresh_token(refresh_token)
      |> put_status(:created)
      |> render("show_ldap.json", token: access_token, validation_warnings: validation_warnings)
    else
      {:ldap_error, error} -> unauthorized(conn, "401_ldap.json", error: error)
      _ -> unauthorized(conn)
    end
  end

  defp authenticate_proxy_login(conn, user_name, "true") do
    case Accounts.get_user_by_name(user_name) do
      nil -> unauthorized(conn)
      user -> create_session(conn, user, "proxy_login")
    end
  end

  defp authenticate_proxy_login(conn, _, _) do
    unauthorized(conn, "proxy_login_disabled.json")
  end

  defp authenticate_and_create_session(conn, user_name, password, access_method) do
    user = Accounts.get_user_by_name(user_name)

    if User.check_password(user, password) do
      create_session(conn, user, access_method)
    else
      unauthorized(conn)
    end
  end

  defp authenticate_using_oidc_and_create_session(conn, params \\ nil)

  defp authenticate_using_oidc_and_create_session(conn, %{"code" => code} = params)
       when is_binary(code) do
    with %{} = params <- Map.delete(params, "auth_realm"),
         {:ok, profile} <- OIDC.authenticate(params),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, "fed")
    else
      error ->
        Logger.info("While authenticating using OpenID Connect... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_oidc_and_create_session(conn, _params) do
    with {:ok, profile} <- OIDC.authenticate(conn),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, "fed")
    else
      error ->
        Logger.info("While authenticating using OpenID Connect... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_auth0_and_create_session(conn, _params) do
    with {:ok, profile} <- Auth0.authenticate(conn),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, "fed")
    else
      error ->
        Logger.info("While authenticating using auth0... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  def ping(conn, _params) do
    send_resp(conn, :ok, "")
  end

  def refresh(conn, _params) do
    with rt when is_binary(rt) <- refresh_token(conn),
         at when is_binary(at) <- conn.assigns[:current_token],
         {:ok, %{token: token, refresh_token: refresh_token}} <- Sessions.refresh(rt, at) do
      conn
      |> put_refresh_token(refresh_token)
      |> put_status(:created)
      |> render("show.json", token: token)
    else
      _ -> unauthorized(conn)
    end
  end

  def destroy(conn, _params) do
    access_token = conn.assigns[:current_token]
    refresh_token = refresh_token(conn)
    Sessions.delete(refresh_token, access_token)

    conn
    |> delete_refresh_token()
    |> send_resp(:no_content, "")
  end

  defp unauthorized(conn, template \\ "401.json", assigns \\ %{}) do
    conn
    |> delete_refresh_token()
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render(template, assigns)
  end

  defp refresh_token(conn) do
    conn
    |> get_req_header("cookie")
    |> List.first("")
    |> Cookies.decode()
    |> Map.get("_td_refresh")
  end

  defp put_refresh_token(conn, refresh_token) do
    put_resp_cookie(conn, "_td_refresh", refresh_token, same_site: "Strict", secure: true)
  end

  defp delete_refresh_token(conn) do
    delete_resp_cookie(conn, "_td_refresh", same_site: "Strict", secure: true)
  end
end
