defmodule TdAuthWeb.PasswordView do
  use TdAuthWeb, :view
  alias TdAuthWeb.UserView

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
