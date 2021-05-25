defmodule TdAuthWeb.PasswordController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback(TdAuthWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.password_swagger_definitions()
  end

  swagger_path :update do
    description("Update user password")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:UpdatePassword), "Update Password")
    end

    response(200, "OK", Schema.ref(:UserResponse))
    response(401, "Unauthorized")
    response(403, "Forbidden")
    response(404, "Not Found")
    response(422, "Unprocessable Entity")
  end

  def update(conn, %{"user" => %{"id" => id, "new_password" => new_password}}) do
    with %{user_id: user_id} = claims <- conn.assigns[:current_resource],
         user <- Accounts.get_user!(id),
         {:can, true} <- {:can, can?(claims, update_password(User)) && id !== user_id},
         {:ok, %User{} = user} <- Accounts.update_user(user, %{password: new_password}) do
      render(conn, "show.json", user: user)
    end
  end

  def update(conn, %{
        "user" => %{
          "new_password" => new_password,
          "old_password" => old_password
        }
      }) do
    with %{user_id: user_id} <- conn.assigns[:current_resource],
         user <- Accounts.get_user!(user_id, preload: :groups),
         {:ok, %User{}} <-
           Accounts.update_user(user, %{password: new_password, old_password: old_password}) do
      render(conn, "show.json", user: user)
    else
      {:error, _error} ->
        send_resp(conn, :unauthorized, "")
    end
  end
end
