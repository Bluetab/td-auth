defmodule TdAuthWeb.SessionController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuth.Auth.Guardian
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.UserController

  defp handle_sign_in(conn, user) do
    custom_claims = %{"user_name": user.user_name,
                      "is_admin": user.is_admin}
    conn
      |> GuardianPlug.sign_in(user, custom_claims)
  end

  def create(conn, %{"user" => %{"user_name" => user_name,
                     "password" => password}}) do
    user = Accounts.get_user_by_name(user_name)

    case UserController.check_password(user, password) do
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

  def destroy(conn, _params) do
    token = GuardianPlug.current_token(conn)
    Guardian.revoke(token)
    send_resp(conn, :ok, "")
  end
end
