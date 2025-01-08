defmodule TdAuthWeb.PasswordController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias Ecto.Changeset
  alias TdAuth.Accounts
  alias TdAuth.Accounts.User

  require Logger

  action_fallback(TdAuthWeb.FallbackController)

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
      {:error, %Changeset{errors: [old_password: _]}} ->
        send_resp(conn, :forbidden, "")

      error ->
        error
    end
  end
end
