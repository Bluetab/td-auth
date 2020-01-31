defmodule TdAuthWeb.PermissionView do
  use TdAuthWeb, :view
  alias TdAuthWeb.PermissionGroupView
  alias TdAuthWeb.PermissionView

  def render("index.json", %{permissions: permissions}) do
    %{data: render_many(permissions, PermissionView, "permission.json")}
  end

  def render("show.json", %{permission: permission}) do
    %{data: render_one(permission, PermissionView, "permission.json")}
  end

  def render("permission.json", %{permission: permission}) do
    %{
      id: permission.id,
      name: permission.name,
      group: render_one(permission.permission_group, PermissionGroupView, "permission_group.json")
    }
  end
end
