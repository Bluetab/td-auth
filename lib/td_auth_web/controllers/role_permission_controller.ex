defmodule TdAuthWeb.RolePermissionController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.Roles
  alias TdAuthWeb.PermissionView
  alias TdAuthWeb.RolePermissionView
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

  swagger_path :create do
    description("Create a role-permission relation")

    parameters do
      role_id(:path, :integer, "Role ID", required: true)

      permission(
        :body,
        Schema.ref(:PermissionRelation),
        "Permissions to associate with the role. Use either permission_id or permission_name"
      )
    end

    response(200, "OK", Schema.ref(:RolePermissionResponse))
  end

  def create(conn, %{"role_id" => role_id, "permission_id" => permission_id}) do
    create(conn, role_id, permission_id)
  end

  def create(conn, %{"role_id" => role_id, "permission_name" => permission_name}) do
    permission = Permissions.get_permission_by_name(permission_name)
    create(conn, role_id, permission)
  end

  def create(_conn, _role_id, nil = _permission) do
    {:error, :not_found}
  end

  def create(conn, role_id, %{id: permission_id} = _permission) do
    create(conn, role_id, permission_id)
  end

  def create(
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

  swagger_path :delete do
    description("Delete a role-permission relation")

    parameters do
      role_id(:path, :integer, "Role ID", required: true)

      permission(
        :body,
        Schema.ref(:PermissionRelation),
        "Permissions to associate with the role. Use either permission_id or permission_name"
      )
    end

    response(204, "No Content")
    response(403, "Forbidden")
    response(422, "Unprocessable Entity")
  end

  def delete(conn, %{"role_id" => role_id, "permission_id" => permission_id}) do
    delete_permission(conn, role_id, permission_id)
  end

  def delete(conn, %{"role_id" => role_id, "permission_name" => permission_name}) do
    permission = Permissions.get_permission_by_name(permission_name)
    delete_permission(conn, role_id, permission)
  end

  defp delete_permission(_conn, _role_id, nil) do
    {:error, :not_found}
  end

  defp delete_permission(conn, role_id, %{id: permission_id}) do
    delete_permission(conn, role_id, permission_id)
  end

  defp delete_permission(conn, role_id, permission_id) do
    claims = conn.assigns[:current_resource]
    ## REVIEW: I think that the id to delete should be requested
    ## first and then send the delete function the schema and not the ids.
    with {:can, true} <- {:can, can?(claims, delete(RolePermission))},
         {:ok, _} <- Roles.delete_permission(role_id, permission_id) do
      send_resp(conn, :no_content, "")
    end
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
