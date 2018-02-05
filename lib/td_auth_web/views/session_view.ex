defmodule TdAuthWeb.SessionView do
  use TdAuthWeb, :view

  def render("show.json", %{token: token}) do
    %{token: token}
  end

end
