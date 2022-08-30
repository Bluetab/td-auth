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

  def render("permission.json", %{
        permission: %{id: id, name: name, permission_group: %Ecto.Association.NotLoaded{}}
      }) do
    %{
      id: id,
      name: name
    }
  end

  def render("permission.json", %{
        permission: %{id: id, name: name, permission_group: permission_group}
      }) do
    %{
      id: id,
      name: name,
      group: render_one(permission_group, PermissionGroupView, "permission_group.json")
    }
  end
end
