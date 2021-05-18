defmodule TdAuthWeb.PasswordController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Claims
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.password_swagger_definitions()
  end

  swagger_path :update do
    description("Update password User")
    produces("application/json")

    parameters do
      id(:path, :integer, "unique identifier", required: true)
      new_password(:path, :string, "new password", required: true)
    end
    response(200, "OK", Schema.ref(:UserResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"user" => %{"id" => id, "new_password" => new_password}}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)},
         user <- Accounts.get_user!(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, %{password: new_password}) do

      render(conn, "show.json", user: user)
    end
  end

  def update(conn, %{"user" => %{
      "new_password" => new_password,
      "old_password" => old_password}}) do

    with %{user_id: user_id} <- conn.assigns[:current_resource],
         user <- Accounts.get_user!(user_id, preload: :groups),
         {:ok, user} <- User.check_password(user, old_password),
         {:ok, %User{}} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :ok, "")
    else
      {:error, error_msg} ->
        render(conn, "show.json", error: %{error: true, msg: error_msg}  )
    end
  end
end
