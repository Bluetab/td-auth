defmodule TdAuthWeb.RolePermissionController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.RolePermission
  alias TdAuth.Permissions.Roles
  alias TdAuthWeb.PermissionView
  alias TdAuthWeb.RolePermissionView

  action_fallback TdAuthWeb.FallbackController

  def show(conn, %{"role_id" => role_id}) do
    permissions =
      role_id
      |> Roles.get_role!()
      |> Roles.get_role_permissions()

    conn
    |> put_view(PermissionView)
    |> render("index.json", permissions: permissions)
  end

  def create(conn, %{"role_id" => role_id, "permission_id" => permission_id}) do
    add_permission(conn, role_id, permission_id)
  end

  def create(conn, %{"role_id" => role_id, "permission_name" => permission_name}) do
    case Permissions.get_permission_by_name(permission_name) do
      %Permission{id: permission_id} -> add_permission(conn, role_id, permission_id)
      nil -> {:error, :not_found}
    end
  end

  defp add_permission(
         conn,
         role_id,
         permission_id
       ) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, create(RolePermission))},
         {:ok, role_permission} <- Roles.add_permission(role_id, permission_id) do
      conn
      |> put_view(RolePermissionView)
      |> render("show.json", role_permission: role_permission)
    end
  end

  def delete(conn, %{"role_id" => role_id, "permission_id" => permission_id}) do
    remove_permission(conn, role_id, permission_id)
  end

  def delete(conn, %{"role_id" => role_id, "permission_name" => permission_name}) do
    case Permissions.get_permission_by_name(permission_name) do
      %Permission{id: permission_id} -> remove_permission(conn, role_id, permission_id)
      nil -> {:error, :not_found}
    end
  end

  defp remove_permission(conn, role_id, permission_id) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, delete(RolePermission))},
         %RolePermission{} = role_permission <-
           Roles.get_role_permission!(role_id, permission_id),
         {:ok, _} <- Roles.remove_permission(role_permission) do
      send_resp(conn, :no_content, "")
    end
  end

  def update(conn, %{"role_id" => role_id, "permissions" => perms}) do
    claims = conn.assigns[:current_resource]

    with %Role{} = role <- Roles.get_role!(role_id),
         {:can, true} <- {:can, can?(claims, update(role))},
         ids <- Enum.map(perms, &Map.get(&1, "id")),
         permissions <- Permissions.list_permissions(id: {:in, ids}),
         {:ok, _} <- Roles.put_permissions(role, permissions) do
      conn
      |> put_view(PermissionView)
      |> render("index.json", permissions: permissions)
    end
  end
end
