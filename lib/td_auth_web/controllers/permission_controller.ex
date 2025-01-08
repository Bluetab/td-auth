defmodule TdAuthWeb.PermissionController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Permission

  action_fallback TdAuthWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(Permission))} do
      permissions = Permissions.list_permissions()
      render(conn, "index.json", permissions: permissions)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with %Permission{} = permission <- Permissions.get_permission!(id),
         {:can, true} <- {:can, can?(claims, view(Permission))} do
      render(conn, "show.json", permission: permission)
    end
  end

  def create(
        conn,
        %{
          "permission" => permission_params
        }
      ) do
    with claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, create(Permission))},
         {:ok, %Permission{} = permission} <-
           Permissions.create_external_permission(permission_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.permission_path(conn, :show, permission))
      |> render("show.json", permission: permission)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with %Permission{} = permission <- Permissions.get_permission!(id),
         {:can, true} <- {:can, can?(claims, delete(Permission))},
         {:ok, _deleted_permission} <- Permissions.delete_permission(permission) do
      send_resp(conn, :no_content, "")
    end
  end
end
