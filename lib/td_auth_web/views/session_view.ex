defmodule TdAuthWeb.SessionView do
  use TdAuthWeb, :view

  def render("show.json", %{token: token, has_permissions: has_permissions}) do
    %{token: token.token, refresh_token: token.refresh_token, has_permissions: has_permissions}
  end

  def render("show.json", %{token: token}) do
    %{token: token.token, refresh_token: token.refresh_token}
  end
end
