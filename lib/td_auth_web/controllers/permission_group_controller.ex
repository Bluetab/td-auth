defmodule TdAuthWeb.PermissionGroupController do
  use TdAuthWeb, :controller

  alias TdAuth.Permissions
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.permission_group_swagger_definitions()
  end

  swagger_path :index do
    description("List groups of permissions")
    response(200, "OK", Schema.ref(:PermissionGroupsResponse))
  end

  def index(conn, _params) do
    permission_groups = Permissions.list_permission_groups()
    render(conn, "index.json", permission_groups: permission_groups)
  end

  swagger_path :create do
    description("Create a group of permissions")
    produces("application/json")

    parameters do
      permission_group(
        :body,
        Schema.ref(:PermissionGroupCreateUpdate),
        "Permission Group create attrs"
      )
    end

    response(201, "Created", Schema.ref(:PermissionGroupResponse))
    response(400, "Client Error")
    response(403, "Unprocessable Entity")
  end

  def create(conn, %{"permission_group" => permission_group_params}) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, current_resource.is_admin},
         {:ok, %PermissionGroup{} = permission_group} <-
           Permissions.create_permission_group(permission_group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.permission_group_path(conn, :show, permission_group))
      |> render("show.json", permission_group: permission_group)
    end
  end

  swagger_path :show do
    description("Show permission group")
    produces("application/json")

    parameters do
      id(:path, :integer, "Group ID", required: true)
    end

    response(200, "OK", Schema.ref(:PermissionGroupResponse))
    response(400, "Client Error")
    response(404, "Not Found")
  end

  def show(conn, %{"id" => id}) do
    permission_group = Permissions.get_permission_group!(id)
    render(conn, "show.json", permission_group: permission_group)
  end

  swagger_path :update do
    description("Update permission")
    produces("application/json")

    parameters do
      permissioon_group(:body, Schema.ref(:PermissionGroupCreateUpdate), "Group update attrs")
      id(:path, :integer, "Permission Group ID", required: true)
    end

    response(200, "OK", Schema.ref(:PermissionGroupResponse))
    response(400, "Client Error")
    response(404, "Not Found")
    response(403, "Unprocessable Entity")
  end

  def update(conn, %{"id" => id, "permission_group" => permission_group_params}) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, current_resource.is_admin},
         permission_group <- Permissions.get_permission_group!(id),
         {:ok, %PermissionGroup{} = permission_group} <-
           Permissions.update_permission_group(permission_group, permission_group_params) do
      render(conn, "show.json", permission_group: permission_group)
    end
  end

  swagger_path :delete do
    description("Delete Permission Group")
    produces("application/json")

    parameters do
      id(:path, :integer, "Permission Group ID", required: true)
    end

    response(204, "")
    response(400, "Client Error")
    response(404, "Not Found")
  end

  def delete(conn, %{"id" => id}) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, current_resource.is_admin},
         permission_group <- Permissions.get_permission_group!(id),
         {:ok, %PermissionGroup{}} <- Permissions.delete_permission_group(permission_group) do
      send_resp(conn, :no_content, "")
    end
  end
end
