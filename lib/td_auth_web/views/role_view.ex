defmodule TdAuthWeb.RoleView do
  use TdAuthWeb, :view

  def render("index.json", %{roles: roles}) do
    %{data: render_many(roles, __MODULE__, "role.json")}
  end

  def render("show.json", %{role: role}) do
    %{data: render_one(role, __MODULE__, "role.json")}
  end

  def render("role.json", %{role: role}) do
    Map.take(role, [:id, :name, :is_default])
  end
end
