defmodule TdAuthWeb.SessionController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.AuditAuth
  alias TdAuth.Auth.Guardian
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuth.Ldap.Ldap
  alias TdAuth.Permissions
  alias TdAuth.Saml.SamlWorker
  alias TdAuthWeb.AuthProvider.ActiveDirectory
  alias TdAuthWeb.AuthProvider.Auth0
  alias TdAuthWeb.AuthProvider.OIDC
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions
  alias TdCache.NonceCache

  require Logger

  def swagger_definitions do
    SwaggerDefinitions.session_swagger_definitions()
  end

  defp handle_sign_in(conn, user, custom_claims) do
    resource = user |> Jason.encode!() |> Jason.decode!()
    GuardianPlug.sign_in(conn, resource, custom_claims)
  end

  swagger_path :create do
    description("Creates a user session")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:SessionCreate), "User session create attrs")
    end

    response(201, "Created", Schema.ref(:Token))
    response(400, "Client Error")
  end

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
    {:ok, _} = AuditAuth.attempt_event("alternative_login", params)
    authenticate_and_create_session(conn, user_name, password, "alternative_login")
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
    tokens = create_tokens(conn, user, access_method)
    {:ok, _} = AuditAuth.session_event(access_method, user)
    create_session_with_tokens(conn, tokens)
  end

  defp create_session_with_tokens(conn, tokens) do
    conn
    |> put_status(:created)
    |> render("show.json", token: tokens)
  end

  defp create_tokens(conn, %User{role: role} = user, access_method) do
    default_permissions = Permissions.default_permissions()
    user_permissions = Permissions.user_permissions(user)
    permission_groups = permission_groups(user, Map.keys(user_permissions) ++ default_permissions)
    claims = claims(user, permission_groups, access_method)
    conn = handle_sign_in(conn, user, claims)
    token = GuardianPlug.current_token(conn)
    %{"jti" => jti, "exp" => exp} = GuardianPlug.current_claims(conn)
    unless role == :admin do
      Permissions.cache_session_permissions(user_permissions, jti, exp)
    end

    {:ok, refresh_token, _full_claims} =
      Guardian.encode_and_sign(user, %{}, token_type: "refresh")

    %{token: token, refresh_token: refresh_token}
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
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using SAML ... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_active_directory_and_create_session(conn, user_name, password) do
    with {:ok, profile} <- ActiveDirectory.authenticate(user_name, password),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using active directory ... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_ldap_and_create_session(conn, user_name, password) do
    with {:ok, profile, validation_warnings} <- Ldap.authenticate(user_name, password),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      tokens = create_tokens(conn, user, nil)

      conn
      |> put_status(:created)
      |> render("show_ldap.json", token: tokens, validation_warnings: validation_warnings)
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

    case User.check_password(user, password) do
      {:ok, user} -> create_session(conn, user, access_method)
      _ -> unauthorized(conn)
    end
  end

  defp authenticate_using_oidc_and_create_session(conn, params \\ nil)

  defp authenticate_using_oidc_and_create_session(conn, %{"code" => code} = params)
       when is_binary(code) do
    with %{} = params <- Map.delete(params, "auth_realm"),
         {:ok, profile} <- OIDC.authenticate(params),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using OpenID Connect... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_oidc_and_create_session(conn, _params) do
    with {:ok, profile} <- OIDC.authenticate(conn),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using OpenID Connect... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp authenticate_using_auth0_and_create_session(conn, _params) do
    with {:ok, profile} <- Auth0.authenticate(conn),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using auth0... #{inspect(error)}")
        unauthorized(conn)
    end
  end

  defp claims(%{role: role, user_name: user_name}, groups, access_method) do
    has_permissions = role == :admin || groups != []

    %{
      user_name: user_name,
      role: to_string(role),
      has_permissions: has_permissions,
      groups: groups
    }
    |> with_access_method(access_method)
  end

  defp with_access_method(claims, "alternative_login" = access_method),
    do: Map.put(claims, :access_method, access_method)

  defp with_access_method(claims, _), do: claims

  defp permission_groups(%{role: :admin}, _permissions), do: []

  defp permission_groups(_user, permissions) when is_list(permissions) do
    Permissions.group_names(permissions)
  end

  def ping(conn, _params) do
    send_resp(conn, :ok, "")
  end

  swagger_path :refresh do
    description("Returns new token")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:RefreshSessionCreate), "User token")
    end

    response(201, "Created", Schema.ref(:Token))
    response(400, "Client Error")
  end

  def refresh(conn, params) do
    refresh_token = params["refresh_token"]

    {:ok, _old_stuff, {token, _new_claims}} =
      Guardian.exchange(refresh_token, "refresh", "access")

    conn
    |> put_status(:created)
    |> render("show.json", token: %{token: token, refresh_token: refresh_token})
  end

  def destroy(conn, _params) do
    token = GuardianPlug.current_token(conn)
    Guardian.revoke(token)
    send_resp(conn, :no_content, "")
  end

  defp unauthorized(conn, template \\ "401.json", assigns \\ %{}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render(template, assigns)
  end
end
