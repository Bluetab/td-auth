defmodule TdAuthWeb.SessionController do
  require Logger

  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuth.Accounts
  #alias TdAuth.Auth.Auth.Plug, as: AuthPlug
  alias TdAuth.Auth.Guardian
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuthWeb.ErrorView
  alias TdAuth.Accounts.User
  alias TdAuthWeb.SwaggerDefinitions
  alias TdAuth.Repo
  alias Poison, as: JSON

  @auth_service Application.get_env(:td_auth, :auth)[:auth_service]

  def swagger_definitions do
    SwaggerDefinitions.session_swagger_definitions()
  end

  defp handle_sign_in(conn, user) do
    user = user |> Repo.preload(:groups)
    custom_claims = %{"user_name": user.user_name,
                      "is_admin": user.is_admin,
                      "groups": Enum.map(user.groups, &(&1.name))}
    conn
      |> GuardianPlug.sign_in(user, custom_claims)
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

  swagger_path :create do
    post "/sessions"
    description "Creates a user session"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:SessionCreate), "User session create attrs"
    end
    response 201, "Created", Schema.ref(:Token)
    response 400, "Client Error"
  end

  def create(conn, %{"user" => %{"user_name" => user_name, "password" => password}}) do
    create_username_password_session(conn, user_name, password)
  end
  def create(conn, _parmas) do
    case fetch_access_token(conn) do
      {:ok, access_token} -> create_access_token_session(conn, access_token)
      _ ->
        Logger.info "Unable to get fetch access token"
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")
    end

  end

  defp create_session(conn, user) do
    conn = handle_sign_in(conn, user)
    token = GuardianPlug.current_token(conn)
    {:ok, refresh_token, _full_claims} = Guardian.encode_and_sign(user, %{}, token_type: "refresh")
    conn
      |> put_status(:created)
      |> render("show.json", token: %{token: token, refresh_token: refresh_token})
  end

  defp create_username_password_session(conn, user_name, password) do
    user = Accounts.get_user_by_name(user_name)

    case User.check_password(user, password) do
      true -> create_session(conn, user)
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")
    end
  end

  defp get_profile_path do
    auth = Application.get_env(:td_auth, :auth)
    "#{auth[:protocol]}://#{auth[:domain]}#{auth[:userinfo]}"
  end

  defp get_profile_mapping do
    auth = Application.get_env(:td_auth, :auth)
    auth[:profile_mapping]
  end

  defp get_profile(access_token) do
    headers = ["Content-Type": "application/json",
               "Accept": "Application/json; Charset=utf-8",
               "Authorization": "Bearer #{access_token}"]

    {status_code, user_info} = @auth_service.get_user_info(get_profile_path(), headers)

    case status_code do
      200 ->
          profile = user_info |> JSON.decode!
          mapping = get_profile_mapping()
          Enum.reduce(mapping, %{}, &Map.put(&2, elem(&1, 0), Map.get(profile, elem(&1, 1), nil)))

      _ -> {:error, status_code}
        Logger.info "Unable to get user profile... status_code '#{status_code}'"
        nil
    end
  end

  defp create_or_update_user(user, attrs) do
    case user do
      nil ->  Accounts.create_user(attrs)
      u ->  Accounts.update_user(u, attrs)
    end
  end

  defp create_profile_session(conn, profile) do
    user_name = profile[:user_name]
    user = Accounts.get_user_by_name(user_name)
    with {:ok, user} <- create_or_update_user(user, profile) do
       create_session(conn, user)
    else
      error ->
        Logger.info "Unable to create or update user '#{user_name}'... #{error}"
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")
    end
  end

  defp create_access_token_session(conn, access_token) do
    case get_profile(access_token) do
      nil ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")

      profile -> create_profile_session(conn, profile)
    end
  end

  def ping(conn, _params) do
    conn
      |> send_resp(:ok, "")
  end

  swagger_path :refresh do
    post "/sessions/refresh"
    description "Returns new token"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:RefreshSessionCreate), "User token"
    end
    response 201, "Created", Schema.ref(:Token)
    response 400, "Client Error"
  end
  def refresh(conn, params) do
    refresh_token = params["refresh_token"]
    {:ok, _old_stuff, {token, _new_claims}} = Guardian.exchange(refresh_token, "refresh", "access")
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
