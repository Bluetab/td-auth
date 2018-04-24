defmodule TdAuthWeb.GroupController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Repo
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.group_swagger_definitions()
  end

  swagger_path :index do
    get "/groups"
    description "List groups"
    response 200, "OK", Schema.ref(:GroupsResponseData)
  end

  def index(conn, _params) do
    groups = Accounts.list_groups()
    render(conn, "index.json", groups: groups)
  end

  swagger_path :create do
    post "/groups"
    description "Create a group"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:GroupCreate), "Group create attrs"
    end
    response 201, "Created", Schema.ref(:GroupResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"group" => group_params}) do
    with {:ok, %Group{} = group} <- Accounts.create_group(group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", group_path(conn, :show, group))
      |> render("show.json", group: group)
    end
  end

  swagger_path :show do
    get "/groups/{id}"
    description "Show group"
    produces "application/json"
    parameters do
      id :path, :integer, "Group ID", required: true
    end
    response 200, "OK", Schema.ref(:GroupResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    group = Accounts.get_group!(id)
    render(conn, "show.json", group: group)
  end

  swagger_path :update do
    put "/groups/{id}"
    description "Update Group"
    produces "application/json"
    parameters do
      group :body, Schema.ref(:GroupUpdate), "Group update attrs"
      id :path, :integer, "Group ID", required: true
    end
    response 200, "OK", Schema.ref(:GroupResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "group" => group_params}) do
    group = Accounts.get_group!(id)

    with {:ok, %Group{} = group} <- Accounts.update_group(group, group_params) do
      render(conn, "show.json", group: group)
    end
  end

  swagger_path :delete do
    delete "/groups/{id}"
    description "Delete Group"
    produces "application/json"
    parameters do
      id :path, :integer, "Group ID", required: true
    end
    response 204, ""
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    group = Accounts.get_group!(id)
    with {:ok, %Group{}} <- Accounts.delete_group(group) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :user_groups do
    get "/users/{id}/groups"
    description "User Groups"
    parameters do
      id :path, :integer, "User ID", required: true
    end
    response 200, "OK", Schema.ref(:GroupsResponseData)
  end

  def user_groups(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user!(user_id) |> Repo.preload(:groups)
    render(conn, "index.json", groups: user.groups)
  end

  swagger_path :add_user_groups do
    post "/users/{user_id}/groups"
    description "Create a group"
    produces "application/json"
    parameters do
      group :body, Schema.ref(:GroupCreate), "Group create attrs"
      user_id :path, :integer, "User ID", required: true
    end
    response 201, "Created", Schema.ref(:GroupResponse)
    response 400, "Client Error"
  end

  def add_user_groups(conn, %{"user_id" => user_id, "group" => group_params}) do
    user = Accounts.get_user!(user_id) |> Repo.preload(:groups)
    {:ok, group} = Accounts.get_or_create_group(group_params)
    with {:ok, %User{} = _updateduser} <- Accounts.add_group_to_user(user, group) do
      conn
      |> put_status(:created)
      |> render("show.json", group: group)
    end
  end

  swagger_path :delete_user_groups do
    delete "/users/{user_id}/groups/{id}"
    description "Create a group"
    produces "application/json"
    parameters do
      user_id :path, :integer, "User ID", required: true
      id :path, :integer, "Group ID", required: true
    end
    response 204, ""
    response 400, "Client Error"
  end

  def delete_user_groups(conn, %{"user_id" => user_id, "id" => group_id}) do
    user = Accounts.get_user!(user_id) |> Repo.preload(:groups)
    group = Accounts.get_group!(group_id)
    with {:ok, %User{}} <- Accounts.delete_group_from_user(user, group) do
      send_resp(conn, :no_content, "")
    end
  end
end
