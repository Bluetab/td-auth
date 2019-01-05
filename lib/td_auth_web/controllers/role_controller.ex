defmodule TdAuthWeb.RoleController do
  require Logger
  use TdAuthWeb, :controller
  use PhoenixSwagger

  import Canada

  alias TdAuth.Permissions.Role
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.role_swagger_definitions()
  end

  swagger_path :index do
    description "List Roles"
    response 200, "OK", Schema.ref(:RolesResponse)
  end

  def index(conn, _params) do
    current_resource = conn.assigns[:current_resource]
    if can?(current_resource, list(Role)) do
      roles = Role.list_roles()
      render(conn, "index.json", roles: roles)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end

  swagger_path :create do
    description "Creates a Role"
    produces "application/json"
    parameters do
      role :body, Schema.ref(:RoleCreateUpdate), "Role create attrs"
    end
    response 201, "Created", Schema.ref(:RoleResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"role" => role_params}) do
    current_resource = conn.assigns[:current_resource]
    case can?(current_resource, create(Role)) do
      true ->
        with {:ok} <- update_to_no_default_role(role_params),
          {:ok, %Role{} = role} <- Role.create_role(role_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.role_path(conn, :show, role))
          |> render("show.json", role: role)
        else
          {:error_unsetting_is_default} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
          {:error, %Ecto.Changeset{}} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
          error ->
            Logger.error("While creating role... #{inspect(error)}")
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
        end
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  end

  swagger_path :show do
    description "Show Role"
    produces "application/json"
    parameters do
      id :path, :integer, "Role ID", required: true
    end
    response 200, "OK", Schema.ref(:RoleResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    role = Role.get_role!(id)
    render(conn, "show.json", role: role)
  end

  swagger_path :update do
    description "Updates Role"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:RoleCreateUpdate), "Role update attrs"
      id :path, :integer, "Role ID", required: true
    end
    response 200, "OK", Schema.ref(:RoleResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    current_resource = conn.assigns[:current_resource]
    role = Role.get_role!(id)
    case can?(current_resource, update(role)) do
      true ->
        with {:ok} <- update_to_no_default_role(role_params),
             {:ok, %Role{} = role} <- Role.update_role(role, role_params) do
          render(conn, "show.json", role: role)
        else
          {:error_unsetting_is_default} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
          {:error, %Ecto.Changeset{}} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
          error ->
            Logger.error("While updating role... #{inspect(error)}")
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
        end
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  end

  swagger_path :delete do
    description "Delete Role"
    produces "application/json"
    parameters do
      id :path, :integer, "Role ID", required: true
    end
    response 204, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    current_resource = conn.assigns[:current_resource]
    role = Role.get_role!(id)
    case can?(current_resource, delete(role)) do
      true ->
        with {:ok, %Role{}} <- Role.delete_role(role) do
          send_resp(conn, :no_content, "")
        else
          _error ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(ErrorView)
            |> render("422.json")
        end
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  end

  defp update_to_no_default_role(%{"is_default" => true}) do
    unset_is_default(Role.get_default_role())
  end
  defp update_to_no_default_role(_), do: {:ok}

  defp unset_is_default(nil), do: {:ok}
  defp unset_is_default(%Role{} = role) do
    case Role.update_role(role, %{is_default: false}) do
      {:ok, _} -> {:ok}
      {:error, _} -> {:error_unsetting_is_default}
    end
  end

end
