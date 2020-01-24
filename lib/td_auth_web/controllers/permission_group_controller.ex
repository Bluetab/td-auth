defmodule TdAuthWeb.PermissionGroupController do
  use TdAuthWeb, :controller

  alias TdAuth.Permissions
  alias TdAuth.Permissions.PermissionGroup

  action_fallback TdAuthWeb.FallbackController

  def index(conn, _params) do
    permission_groups = Permissions.list_permission_groups()
    render(conn, "index.json", permission_groups: permission_groups)
  end

  def create(conn, %{"permission_group" => permission_group_params}) do
    current_resource = conn.assigns[:current_resource]

    with true <- current_resource.is_admin,
         {:ok, %PermissionGroup{} = permission_group} <-
           Permissions.create_permission_group(permission_group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.permission_group_path(conn, :show, permission_group))
      |> render("show.json", permission_group: permission_group)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      error ->
        error
    end
  end

  def show(conn, %{"id" => id}) do
    permission_group = Permissions.get_permission_group!(id)
    render(conn, "show.json", permission_group: permission_group)
  end

  def update(conn, %{"id" => id, "permission_group" => permission_group_params}) do
    current_resource = conn.assigns[:current_resource]
    permission_group = Permissions.get_permission_group!(id)

    with true <- current_resource.is_admin,
         {:ok, %PermissionGroup{} = permission_group} <-
           Permissions.update_permission_group(permission_group, permission_group_params) do
      render(conn, "show.json", permission_group: permission_group)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      error ->
        error
    end
  end

  def delete(conn, %{"id" => id}) do
    current_resource = conn.assigns[:current_resource]
    permission_group = Permissions.get_permission_group!(id)

    with true <- current_resource.is_admin,
         {:ok, %PermissionGroup{}} <- Permissions.delete_permission_group(permission_group) do
      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      error ->
        error
    end
  end
end
