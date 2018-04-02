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
    response 201, "Created", Schema.ref(:SessionResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"user" => %{"user_name" => user_name,
                     "password" => password}}) do
    user = Accounts.get_user_by_name(user_name)

    case User.check_password(user, password) do
      true ->
        conn = handle_sign_in(conn, user)
        token = GuardianPlug.current_token(conn)
        conn
          |> put_status(:created)
          |> render("show.json", token: token)
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

# TOFIX: A la espera de que actualicen la versión de la librería
  # def refresh(conn, _params) do
  #   resource = GuardianPlug.current_resource(conn)
  #   token =
  #     conn
  #       |> GuardianPlug.remember_me(resource)
  #       |> GuardianPlug.current_token(conn)
  #   conn
  #     |> put_status(:created)
  #     |> render("show.json", token: token)
  # end

  def destroy(conn, _params) do
    token = GuardianPlug.current_token(conn)
    Guardian.revoke(token)
    send_resp(conn, :ok, "")
  end
end
