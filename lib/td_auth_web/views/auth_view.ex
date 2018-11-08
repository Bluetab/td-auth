defmodule TdAuthWeb.AuthView do
  use TdAuthWeb, :view

  def render("index.json", %{urls: urls}) do
    %{data: urls |> Enum.map(&%{url: &1})}
  end
end
