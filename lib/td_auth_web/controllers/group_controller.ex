defmodule TdAuthWeb.GroupController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Auth.Claims
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.group_swagger_definitions()
  end

  swagger_path :index do
    description("List groups")
    response(200, "OK", Schema.ref(:GroupsResponseData))
  end

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(Group))},
         groups <- Accounts.list_groups() do
      render(conn, "index.json", groups: groups)
    end
  end

  swagger_path :create do
    description("Create a group")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:GroupCreate), "Group create attrs")
    end

    response(201, "Created", Schema.ref(:GroupResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"group" => group_params}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)},
         {:ok, %Group{} = group} <- Accounts.create_group(group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.group_path(conn, :show, group))
      |> render("show.json", group: group)
    end
  end

  swagger_path :show do
    description("Show group")
    produces("application/json")

    parameters do
      id(:path, :integer, "Group ID", required: true)
    end

    response(200, "OK", Schema.ref(:GroupResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)},
         group <- Accounts.get_group!(id, preload: :users) do
      render(conn, "show.json", group: group)
    end
  end

  swagger_path :update do
    description("Update Group")
    produces("application/json")

    parameters do
      group(:body, Schema.ref(:GroupUpdate), "Group update attrs")
      id(:path, :integer, "Group ID", required: true)
    end

    response(200, "OK", Schema.ref(:GroupResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "group" => group_params}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)},
         group <- Accounts.get_group!(id, preload: :users),
         {:ok, %Group{} = group} <- Accounts.update_group(group, group_params) do
      render(conn, "show.json", group: group)
    end
  end

  swagger_path :delete do
    description("Delete Group")
    produces("application/json")

    parameters do
      id(:path, :integer, "Group ID", required: true)
    end

    response(204, "")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)},
         group <- Accounts.get_group!(id),
         {:ok, %Group{}} <- Accounts.delete_group(group) do
      send_resp(conn, :no_content, "")
    end
  end
end
