defmodule TdAuthWeb.PermissionController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Roles
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.permission_swagger_definitions()
  end

  swagger_path :index do
    description("List Permissions")
    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def index(conn, _params) do
    permissions = Permissions.list_permissions()
    render(conn, "index.json", permissions: permissions)
  end

  swagger_path :show do
    description("Show Permission")
    produces("application/json")

    parameters do
      id(:path, :integer, "Permission ID", required: true)
    end

    response(200, "OK", Schema.ref(:PermissionResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    permission = Permissions.get_permission!(id)
    render(conn, "show.json", permission: permission)
  end

  swagger_path :get_role_permissions do
    description("List Role Permissions")

    parameters do
      role_id(:path, :integer, "Role ID", required: true)
    end

    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def get_role_permissions(conn, %{"role_id" => role_id}) do
    permissions =
      role_id
      |> Roles.get_role!()
      |> Roles.get_role_permissions()

    render(conn, "index.json", permissions: permissions)
  end

  swagger_path :add_permissions_to_role do
    description("Add Permissions to Role")

    parameters do
      role_id(:path, :integer, "Role ID", required: true)
      permissions(:body, Schema.ref(:AddPermissions), "Add Permissions to Role attrs")
    end

    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def add_permissions_to_role(conn, %{"role_id" => role_id, "permissions" => perms}) do
    current_resource = conn.assigns[:current_resource]

    with role <- Roles.get_role!(role_id),
         {:can, true} <- {:can, can?(current_resource, add_permissions_to_role(role))} do
      permissions = Enum.map(perms, &Permissions.get_permission!(Map.get(&1, "id")))

      Roles.add_permissions_to_role(role, permissions)
      render(conn, "index.json", permissions: permissions)
    end
  end
end
