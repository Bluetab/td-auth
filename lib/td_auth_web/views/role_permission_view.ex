defmodule TdAuthWeb.RolePermissionView do
  use TdAuthWeb, :view

  def render("show.json", %{role_permission: role_permission}) do
    %{data: render_one(role_permission, __MODULE__, "role_permission.json")}
  end

  def render("role_permission.json", %{role_permission: role_permision}) do
    Map.take(role_permision, [:role_id, :permission_id])
  end
end
