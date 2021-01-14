defmodule TdAuthWeb.RoleController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.Roles
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.role_swagger_definitions()
  end

  swagger_path :index do
    description("List Roles")
    response(200, "OK", Schema.ref(:RolesResponse))
  end

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, list(Role))},
         roles <- Roles.list_roles() do
      render(conn, "index.json", roles: roles)
    end
  end

  swagger_path :create do
    description("Creates a Role")
    produces("application/json")

    parameters do
      role(:body, Schema.ref(:RoleCreateUpdate), "Role create attrs")
    end

    response(201, "Created", Schema.ref(:RoleResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"role" => role_params}) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, create(Role))},
         {:ok, %{role: %Role{} = role}} <- Roles.create_role(role_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.role_path(conn, :show, role))
      |> render("show.json", role: role)
    end
  end

  swagger_path :show do
    description("Show Role")
    produces("application/json")

    parameters do
      id(:path, :integer, "Role ID", required: true)
    end

    response(200, "OK", Schema.ref(:RoleResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    role = Roles.get_role!(id)
    render(conn, "show.json", role: role)
  end

  swagger_path :update do
    description("Updates Role")
    produces("application/json")

    parameters do
      data_domain(:body, Schema.ref(:RoleCreateUpdate), "Role update attrs")
      id(:path, :integer, "Role ID", required: true)
    end

    response(200, "OK", Schema.ref(:RoleResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    claims = conn.assigns[:current_resource]
    role = Roles.get_role!(id)

    with {:can, true} <- {:can, can?(claims, update(role))},
         {:ok, %{role: %Role{} = role}} <- Roles.update_role(role, role_params) do
      render(conn, "show.json", role: role)
    end
  end

  swagger_path :delete do
    description("Delete Role")
    produces("application/json")

    parameters do
      id(:path, :integer, "Role ID", required: true)
    end

    response(204, "OK")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with %Role{} = role <- Roles.get_role!(id),
         {:can, true} <- {:can, can?(claims, delete(role))},
         {:ok, %Role{}} <- Roles.delete_role(role) do
      send_resp(conn, :no_content, "")
    end
  end
end
