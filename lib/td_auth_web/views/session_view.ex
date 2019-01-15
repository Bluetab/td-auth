defmodule TdAuthWeb.SessionView do
  use TdAuthWeb, :view

  def render("show.json", %{token: token}) do
    %{token: token.token, refresh_token: token.refresh_token}
  end

  def render("user.json", %{user: user}) do
    %{
      user_name: user.user_name,
      password: user.password
    }
  end
end
