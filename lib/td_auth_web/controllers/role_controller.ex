defmodule TdAuthWeb.RoleController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.Roles

  require Logger

  action_fallback TdAuthWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(Role))},
         roles <- Roles.list_roles() do
      render(conn, "index.json", roles: roles)
    end
  end

  def create(conn, %{"role" => role_params}) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, create(Role))},
         {:ok, %{role: role}} <- Roles.create_role(role_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.role_path(conn, :show, role))
      |> render("show.json", role: role)
    end
  end

  def show(conn, %{"id" => id}) do
    role = Roles.get_role!(id)
    render(conn, "show.json", role: role)
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    claims = conn.assigns[:current_resource]
    role = Roles.get_role!(id)

    with {:can, true} <- {:can, can?(claims, update(role))},
         {:ok, %{role: role}} <- Roles.update_role(role, role_params) do
      render(conn, "show.json", role: role)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with %Role{} = role <- Roles.get_role!(id),
         {:can, true} <- {:can, can?(claims, delete(role))},
         {:ok, _} <- Roles.delete_role(role) do
      send_resp(conn, :no_content, "")
    end
  end
end
