defmodule TdAuthWeb.SessionController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuth.Accounts
  alias TdAuth.Auth.Guardian
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuthWeb.ErrorView
  alias TdAuth.Accounts.User
  alias TdAuthWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.session_swagger_definitions()
  end

  defp handle_sign_in(conn, user) do
    custom_claims = %{"user_name": user.user_name,
                      "is_admin": user.is_admin}
    conn
      |> GuardianPlug.sign_in(user, custom_claims)
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

  def create(conn, %{"user" => %{"user_name" => user_name,
                     "password" => password}}) do
    user = Accounts.get_user_by_name(user_name)

    case User.check_password(user, password) do
      true ->
        conn = handle_sign_in(conn, user)
        token = GuardianPlug.current_token(conn)
        {:ok, refresh_token, _full_claims} = Guardian.encode_and_sign(user, %{}, token_type: "refresh")
        conn
          |> put_status(:created)
          |> render("show.json", token: %{token: token, refresh_token: refresh_token})
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, :"401.json")
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
