defmodule TdAuthWeb.PermissionGroupView do
  use TdAuthWeb, :view
  alias TdAuthWeb.PermissionGroupView

  def render("index.json", %{permission_groups: permission_groups}) do
    %{data: render_many(permission_groups, PermissionGroupView, "permission_group.json")}
  end

  def render("show.json", %{permission_group: permission_group}) do
    %{data: render_one(permission_group, PermissionGroupView, "permission_group.json")}
  end

  def render("permission_group.json", %{permission_group: permission_group}) do
    %{id: permission_group.id, name: permission_group.name}
  end
end
