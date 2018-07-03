defmodule TdAuthWeb.PermissionView do
  use TdAuthWeb, :view
  alias TdAuthWeb.PermissionView

  def render("index.json", %{permissions: permissions}) do
    %{data: render_many(permissions, PermissionView, "permission.json")}
  end

  def render("show.json", %{permission: permission}) do
    %{data: render_one(permission, PermissionView, "permission.json")}
  end

  def render("permission.json", %{permission: permission}) do
    %{id: permission.id,
      name: permission.name}
  end
end
