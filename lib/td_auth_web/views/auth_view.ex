defmodule TdAuthWeb.AuthView do
  use TdAuthWeb, :view

  def render("index.json", %{auth_methods: auth_methods}) do
    %{data: auth_methods}
  end
end
