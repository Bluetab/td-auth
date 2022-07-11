defmodule TdAuthWeb.SessionView do
  use TdAuthWeb, :view

  def render("show.json", %{token: token}) do
    %{token: token}
  end

  def render("show_ldap.json", %{token: token, validation_warnings: validation_warnings}) do
    %{
      token: token,
      validation_warnings: validation_warnings
    }
  end

  def render("user.json", %{user: user}) do
    %{
      user_name: user.user_name,
      password: user.password
    }
  end
end
