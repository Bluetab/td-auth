defmodule TdAuthWeb.SessionController do
  require Logger

  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias Gettext.Interpolation
  alias Poison, as: JSON
  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Guardian
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuth.Permissions
  alias TdAuth.Permissions.Role
  alias TdAuth.Repo
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions
  alias TdPerms.TaxonomyCache

  @auth_service Application.get_env(:td_auth, :auth)[:auth_service]

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

  def create(conn, %{"auth_realm" => "ldap", "user" => %{"user_name" => user_name, "password" => password}}) do
    authenticate_using_ldap_and_create_session(conn, user_name, password)
  end
  def create(conn, %{"user" => %{"user_name" => user_name, "password" => password}}) do
    authenticate_and_create_session(conn, user_name, password)
  end
  def create(conn, _params) do
      authenticate_using_auth0_and_create_session(conn)
  end

  defp create_session(conn, user) do
    user_claims = retrieve_user_claims(user)
    acl_entries = retrieve_acl_with_permissions(user, user_claims.gids)
    custom_claims = user_claims |> Map.put(:has_permissions, has_user_permissions?(user, acl_entries))
    conn = handle_sign_in(conn, user, custom_claims)
    token = GuardianPlug.current_token(conn)

    # Load permissions cache
    %{"jti" => jti, "exp" => exp} = conn |> GuardianPlug.current_claims()
    Permissions.cache_session_permissions(acl_entries, jti, exp)

    {:ok, refresh_token, _full_claims} =
      Guardian.encode_and_sign(user, %{}, token_type: "refresh")

    conn
    |> put_status(:created)
    |> render(
      "show.json",
      token: %{
        token: token,
        refresh_token: refresh_token
      }
    )
  end

  defp has_user_permissions?(%User{is_admin: true}, _acl_entries), do: true

  defp has_user_permissions?(%User{}, acl_entries) do
    acl_entries
    |> Enum.any?(&(Map.has_key?(&1, :permissions) && !Enum.empty?(&1.permissions)))
  end

  defp retrieve_acl_with_permissions(%User{is_admin: true}, _), do: []
  defp retrieve_acl_with_permissions(%User{} = user, gids) do
    acl_entries = Permissions.retrieve_acl_with_permissions(user.id, gids)
    default_acl_entries = case Role.get_default_role do
      nil -> []
      role ->
        permissions = role
        |> Repo.preload(:permissions)
        |> Map.get(:permissions)
        |> Enum.map(&(&1.name))

        TaxonomyCache.get_root_domain_ids()
        |> Enum.map(&%{
            permissions: permissions,
            resource_type: "domain",
            resource_id: &1,
          })
    end
    acl_entries ++ default_acl_entries
  end

  defp authenticate_and_create_session(conn, user_name, password) do
    user = Accounts.get_user_by_name(user_name)

    case User.check_password(user, password) do
      true ->
        create_session(conn, user)

      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  defp authenticate_using_ldap_and_create_session(conn, user_name, password) do
    with {:ok, ldap_conn} <- Exldap.open,
          :ok <- ldap_authenticate(ldap_conn, user_name, password),
         {:ok, user} <- create_or_update_ldap_user(ldap_conn, user_name) do
             create_session(conn, user)
    else
      error ->
        Logger.error("While authenticating using ldap and creating session... #{inspect(error)}")
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  defp ldap_authenticate(ldap_conn, user_name, password) do
    bind_pattern = get_ldap_bind_pattern()
    {:ok, bind} = bind_pattern
    |> Interpolation.to_interpolatable
    |> Interpolation.interpolate(%{user_name: user_name})
    case Exldap.verify_credentials(ldap_conn, bind, password) do
      :ok -> :ok
      error ->
        error
    end
  end

  defp create_or_update_ldap_user(ldap_conn, user_name) do
    search_path  = get_ldap_search_path()
    search_field = get_ldap_search_field()
    case Exldap.search_field(ldap_conn, search_path, search_field, user_name) do
      {:ok, search_results} ->
        entry = Enum.at(search_results, 0)
        mapping = get_ldap_profile_mapping()
        profile = Enum.reduce(mapping, %{}, fn({k, v}, acc) ->
          attr = Exldap.search_attributes(entry, v)
          Map.put(acc, k, attr)
        end)
        user = Accounts.get_user_by_name(profile["user_name"])
        create_or_update_user(user, profile)
      error -> error
    end
  end

  defp get_ldap_profile_mapping do
    ldap_config = Application.get_env(:td_auth, :ldap)
    Poison.decode!(ldap_config[:profile_mapping])
  end

  defp get_ldap_bind_pattern do
    ldap_config = Application.get_env(:td_auth, :ldap)
    ldap_config[:bind_pattern]
  end

  defp get_ldap_search_path do
    ldap_config = Application.get_env(:td_auth, :ldap)
    ldap_config[:search_path]
  end

  defp get_ldap_search_field do
    ldap_config = Application.get_env(:td_auth, :ldap)
    ldap_config[:search_field]
  end

  defp authenticate_using_auth0_and_create_session(conn) do
    case fetch_access_token(conn) do
      {:ok, access_token} ->
        create_access_token_session(conn, access_token)
      _ ->
        Logger.info("Unable to get fetch access token")
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  # defp get_audience do
  #   auth = Application.get_env(:td_auth, :auth)
  #   auth[:audience]
  # end
  #
  # defp check_audience(conn) do
  #   audience = get_audience()
  #   case audience do
  #     nil -> true
  #     _ ->
  #       conn
  #       |> AuthPlug.current_claims
  #       |> Map.get("aud")
  #       |> Enum.member?(audience)
  #   end
  # end

  # defp fetch_access_token(conn) do
  #   case check_audience(conn) do
  #     true ->
  #        {:ok, AuthPlug.current_token(conn)}
  #     false ->
  #       Logger.info "Unable to validate token audience"
  #       {:missing_audience}
  #   end
  # end

  defp fetch_access_token(conn) do
    headers = get_req_header(conn, "authorization")
    fetch_access_token_from_header(headers)
  end

  defp fetch_access_token_from_header([]), do: :no_access_token_found

  defp fetch_access_token_from_header([token | tail]) do
    trimmed_token = String.trim(token)

    case Regex.run(~r/^Bearer (.*)$/, trimmed_token) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> fetch_access_token_from_header(tail)
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

  defp get_auth0_profile_path do
    auth = Application.get_env(:td_auth, :auth)
    "#{auth[:protocol]}://#{auth[:domain]}#{auth[:userinfo]}"
  end

  defp get_auth0_profile_mapping do
    auth = Application.get_env(:td_auth, :auth)
    auth[:profile_mapping]
  end

  defp get_auth0_profile(access_token) do
    headers = [
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8",
      Authorization: "Bearer #{access_token}"
    ]

    {status_code, user_info} = @auth_service.get_user_info(get_auth0_profile_path(), headers)

    case status_code do
      200 ->
        profile = user_info |> JSON.decode!()
        mapping = get_auth0_profile_mapping()
        Enum.reduce(mapping, %{}, &Map.put(&2, elem(&1, 0), Map.get(profile, elem(&1, 1), nil)))

      _ ->
        {:error, status_code}
        Logger.info("Unable to get user profile... status_code '#{status_code}'")
        nil
    end
  end

  defp create_or_update_user(user, attrs) do
    case user do
      nil -> Accounts.create_user(attrs)
      u -> Accounts.update_user(u, attrs)
    end
  end

  defp create_profile_session(conn, profile) do
    user_name = profile[:user_name]
    user = Accounts.get_user_by_name(user_name)

    with {:ok, user} <- create_or_update_user(user, profile) do
      create_session(conn, user)
    else
      error ->
        Logger.info("Unable to create or update user '#{user_name}'... #{error}")

        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  defp create_access_token_session(conn, access_token) do
    case get_auth0_profile(access_token) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")

      profile ->
        create_profile_session(conn, profile)
    end
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
