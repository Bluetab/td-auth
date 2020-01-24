defmodule TdAuthWeb.PermissionController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Permissions.Role
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  @enrich_attrs [:permission_group]

  def swagger_definitions do
    SwaggerDefinitions.permission_swagger_definitions()
  end

  swagger_path :index do
    description("List Permissions")
    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def index(conn, _params) do
    permissions = Permissions.list_permissions(@enrich_attrs)
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
    permission = Permissions.get_permission!(id, @enrich_attrs)
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
    role = Role.get_role!(role_id)

    permissions =
      role
      |> Role.get_role_permissions()
      |> Permissions.preload_options(@enrich_attrs)

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
    role = Role.get_role!(role_id)

    case can?(current_resource, add_permissions_to_role(role)) do
      true ->
        permissions =
          Enum.map(perms, &Permissions.get_permission!(Map.get(&1, "id"), @enrich_attrs))

        Role.add_permissions_to_role(role, permissions)
        render(conn, "index.json", permissions: permissions)

      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  end

  swagger_path :permissions_to_group do
    description("Add Permissions to a Group")

    parameters do
      permission_group_id(:path, :integer, "Permission Group ID", required: true)
      permissions(:body, Schema.ref(:AddPermissions), "Add Permissions to Role attrs")
    end

    response(200, "OK", Schema.ref(:PermissionsResponse))
  end

  def permissions_to_group(conn, %{"permission_group_id" => permission_group_id, "permissions" => perms}) do
    current_resource = conn.assigns[:current_resource]
    permission_group = Permissions.get_permission_group!(permission_group_id)
    permissions = Enum.map(perms, &Permissions.get_permission!(Map.get(&1, "id")))
    with true <- current_resource.is_admin,
      {:ok, %PermissionGroup{permissions: permissions}} <- Permissions.update_permission_group(permission_group, %{permissions: permissions}) do
        permissions = Permissions.preload_options(permissions, [:permission_group])  
        render(conn, "index.json", permissions: permissions)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      error -> error
    end
  end
end
