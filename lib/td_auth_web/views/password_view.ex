defmodule TdAuthWeb.PasswordView do
  use TdAuthWeb, :view
  alias TdAuthWeb.UserView

  require Logger

  def render("show.json", %{error: data_error}), do:  data_error

  def render("show.json", %{user: user} = assigns) do
    %{
      data:
        render_one(
          user,
          UserView,
          "user.json",
          Map.drop(assigns, [:user])
        )
    }
  end
end
