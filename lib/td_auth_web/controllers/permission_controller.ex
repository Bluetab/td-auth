defmodule TdAuthWeb.PermissionController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Permission
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
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(current_resource, list(Permission))} do
      permissions = Permissions.list_permissions()
      render(conn, "index.json", permissions: permissions)
    end
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
    current_resource = conn.assigns[:current_resource]

    with %Permission{} = permission <- Permissions.get_permission!(id),
         {:can, true} <- {:can, can?(current_resource, view(permission))} do
      render(conn, "show.json", permission: permission)
    end
  end
end
