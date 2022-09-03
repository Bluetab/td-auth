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
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(Permission))} do
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
    claims = conn.assigns[:current_resource]

    with %Permission{} = permission <- Permissions.get_permission!(id),
         {:can, true} <- {:can, can?(claims, view(Permission))} do
      render(conn, "show.json", permission: permission)
    end
  end

  swagger_path :create do
    description("Creates a new permission")
    produces("application/json")

    parameters do
      configuration(
        :body,
        Schema.ref(:CreatePermission),
        "Parameters used to create a permission"
      )
    end

    response(200, "OK", Schema.ref(:PermissionResponse))
    response(403, "Forbidden")
    response(422, "Client Error")
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

  swagger_path :delete do
    description("Delete Permission")
    produces("application/json")

    parameters do
      id(:path, :integer, "Permission ID", required: true)
    end

    response(204, "No Content")
    response(403, "Forbidden")
    response(422, "Unprocessable Entity")
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
