defmodule TdAuthWeb.SessionController do
  require Logger

  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias Jason, as: JSON
  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Guardian
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuth.Permissions
  alias TdAuth.Permissions.Role
  alias TdAuth.Repo
  alias TdAuth.Saml.SamlWorker
  alias TdAuthWeb.AuthProvider.ActiveDirectory
  alias TdAuthWeb.AuthProvider.Auth0
  alias TdAuthWeb.AuthProvider.Ldap
  alias TdAuthWeb.AuthProvider.OIDC
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions
  alias TdCache.NonceCache
  alias TdCache.TaxonomyCache

  def swagger_definitions do
    SwaggerDefinitions.session_swagger_definitions()
  end

  defp handle_sign_in(conn, user, custom_claims) do
    resource = user |> JSON.encode!() |> JSON.decode!()

    conn
    |> GuardianPlug.sign_in(resource, custom_claims)
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
      |> JSON.encode!()
      |> NonceCache.create_nonce()

    redirect(conn, to: "/saml#nonce=#{nonce}")
  end

  def create(conn, %{
        "auth_realm" => "active_directory",
        "user" => %{"user_name" => user_name, "password" => password}
      }) do
    authenticate_using_active_directory_and_create_session(conn, user_name, password)
  end

  def create(conn, %{
        "auth_realm" => "ldap",
        "user" => %{"user_name" => user_name, "password" => password}
      }) do
    authenticate_using_ldap_and_create_session(conn, user_name, password)
  end

  def create(conn, %{"auth_realm" => "oidc"}) do
    authenticate_using_oidc_and_create_session(conn)
  end

  def create(conn, %{"auth_realm" => auth_realm, "nonce" => nonce}) do
    case NonceCache.pop(nonce) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")

      json ->
        create_nonce_session(conn, auth_realm, json)
    end
  end

  def create(conn, %{"user" => %{"user_name" => user_name, "password" => password}}) do
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

  defp create(conn, %{"authorization" => authorization}, _params) do
    authenticate_using_auth0_and_create_session(conn, authorization)
  end

  defp create(conn, _headers, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ErrorView)
    |> render("422.json")
  end

  defp create_session(conn, user, access_method) do
    tokens = create_tokens(conn, user, access_method)
    create_session_with_tokens(conn, tokens)
  end

  defp create_session_with_tokens(conn, tokens) do
    conn
    |> put_status(:created)
    |> render("show.json", token: tokens)
  end

  defp create_tokens(conn, user, access_method) do
    user_claims = retrieve_user_claims(user)
    acl_entries = retrieve_acl_with_permissions(user, user_claims.gids)

    custom_claims =
      user_claims |> Map.put(:has_permissions, has_user_permissions?(user, acl_entries))

    custom_claims =
      if access_method !== nil && access_method == "alternative_login" do
        user_claims |> Map.put(:has_permissions, has_user_permissions?(user, acl_entries))
        custom_claims |> Map.put(:access_method, access_method)
      else
        user_claims |> Map.put(:has_permissions, has_user_permissions?(user, acl_entries))
      end

    conn = handle_sign_in(conn, user, custom_claims)
    token = GuardianPlug.current_token(conn)

    # Load permissions cache
    %{"jti" => jti, "exp" => exp} = conn |> GuardianPlug.current_claims()
    Permissions.cache_session_permissions(acl_entries, jti, exp)

    {:ok, refresh_token, _full_claims} =
      Guardian.encode_and_sign(user, %{}, token_type: "refresh")

    %{token: token, refresh_token: refresh_token}
  end

  def create_nonce_session(conn, "saml", json) do
    params = JSON.decode!(json)

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

  defp has_user_permissions?(%User{is_admin: true}, _acl_entries), do: true

  defp has_user_permissions?(%User{}, acl_entries) do
    acl_entries
    |> Enum.any?(&(Map.has_key?(&1, :permissions) && !Enum.empty?(&1.permissions)))
  end

  defp retrieve_acl_with_permissions(%User{is_admin: true}, _), do: []

  defp retrieve_acl_with_permissions(%User{} = user, gids) do
    acl_entries = Permissions.retrieve_acl_with_permissions(user.id, gids)

    default_acl_entries =
      case Role.get_default_role() do
        nil ->
          []

        role ->
          permissions =
            role
            |> Repo.preload(:permissions)
            |> Map.get(:permissions)
            |> Enum.map(& &1.name)

          TaxonomyCache.get_root_domain_ids()
          |> Enum.map(
            &%{
              permissions: permissions,
              resource_type: "domain",
              resource_id: &1
            }
          )
      end

    acl_entries ++ default_acl_entries
  end

  defp authenticate_using_saml_and_create_session(conn, saml_response, saml_encoding) do
    with {:ok, profile} <- SamlWorker.validate(saml_response, saml_encoding),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using SAML ... #{inspect(error)}")

        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")
    end
  end

  defp authenticate_using_active_directory_and_create_session(conn, user_name, password) do
    with {:ok, profile} <- ActiveDirectory.authenticate(user_name, password),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using active directory ... #{inspect(error)}")

        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")
    end
  end

  defp authenticate_using_ldap_and_create_session(conn, user_name, password) do
    with {:ok, profile, description} <- Ldap.authenticate(user_name, password),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      tokens = create_tokens(conn, user, nil)
      conn
      |> put_status(:created)
      |> render("show_ldap.json", token: tokens, description: description)
    else
      {:verify_error, error, description} ->
        Logger.info("Invalid verification of correct ldap user: #{inspect(error)}")

        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401_ldap.json", description: description)
      error ->
        Logger.info("While authenticating using ldap: #{inspect(error)}")

        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")
    end
  end

  defp authenticate_proxy_login(conn, user_name, "true") do
    case Accounts.get_user_by_name(user_name) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")

      user ->
        create_session(conn, user, "proxy_login")
    end
  end

  defp authenticate_proxy_login(conn, _, _) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("proxy_login_disabled.json")
  end

  defp authenticate_and_create_session(conn, user_name, password, access_method) do
    user = Accounts.get_user_by_name(user_name)

    case User.check_password(user, password) do
      true ->
        create_session(conn, user, access_method)

      _ ->
        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")
    end
  end

  defp authenticate_using_oidc_and_create_session(conn) do
    authorization_header = get_req_header(conn, "authorization")

    with {:ok, profile} <- OIDC.authenticate(authorization_header),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using OpenID Connect... #{inspect(error)}")

        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")
    end
  end

  defp authenticate_using_auth0_and_create_session(conn, authorization_header) do
    with {:ok, profile} <- Auth0.authenticate(authorization_header),
         {:ok, user} <- Accounts.create_or_update_user(profile) do
      create_session(conn, user, nil)
    else
      error ->
        Logger.info("While authenticating using auth0... #{inspect(error)}")

        conn
        |> put_status(:unauthorized)
        |> put_view(ErrorView)
        |> render("401.json")
    end
  end

  defp retrieve_user_claims(user) do
    user = user |> Repo.preload(:groups)

    %{
      user_name: user.user_name,
      is_admin: user.is_admin,
      gids: user.groups |> Enum.map(& &1.id)
    }
  end

  def ping(conn, _params) do
    conn
    |> send_resp(:ok, "")
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
    send_resp(conn, :ok, "")
  end
end
