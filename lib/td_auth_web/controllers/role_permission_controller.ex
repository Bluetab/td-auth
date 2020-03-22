defmodule TdAuthWeb.RolePermissionController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Roles
  alias TdAuthWeb.PermissionView
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.permission_swagger_definitions()
  end

  swagger_path :show do
    description("List Role Permissions")

    parameters do
      role_id(:path, :integer, "Role ID", required: true)
    end

    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def show(conn, %{"role_id" => role_id}) do
    permissions =
      role_id
      |> Roles.get_role!()
      |> Roles.get_role_permissions()

    conn
    |> put_view(PermissionView)
    |> render("index.json", permissions: permissions)
  end

  swagger_path :update do
    description("Modify Permissions of a Role")

    parameters do
      role_id(:path, :integer, "Role ID", required: true)
      permissions(:body, Schema.ref(:AddPermissions), "Permissions to associate with the role")
    end

    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def update(conn, %{"role_id" => role_id, "permissions" => perms}) do
    current_resource = conn.assigns[:current_resource]

    with role <- Roles.get_role!(role_id),
         {:can, true} <- {:can, can?(current_resource, update(role))},
         ids <- Enum.map(perms, &Map.get(&1, "id")),
         permissions <- Permissions.list_permissions(id: {:in, ids}) do
      Roles.put_permissions(role, permissions)
      conn
      |> put_view(PermissionView)
      |> render("index.json", permissions: permissions)
    end
  end
end
