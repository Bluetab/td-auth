defmodule TdAuthWeb.GroupController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  import Canada

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Repo
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.group_swagger_definitions()
  end

  swagger_path :index do
    description "List groups"
    response 200, "OK", Schema.ref(:GroupsResponseData)
  end

  def index(conn, _params) do
    current_resource = conn.assigns[:current_resource]
    case current_resource |> can?(list(Group)) do
      true ->
        groups = Accounts.list_groups()
        render(conn, "index.json", groups: groups)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :create do
    description "Create a group"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:GroupCreate), "Group create attrs"
    end
    response 201, "Created", Schema.ref(:GroupResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"group" => group_params}) do
    case is_admin?(conn) do
      true ->
        with {:ok, %Group{} = group} <- Accounts.create_group(group_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", group_path(conn, :show, group))
          |> render("show.json", group: group)
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :show do
    description "Show group"
    produces "application/json"
    parameters do
      id :path, :integer, "Group ID", required: true
    end
    response 200, "OK", Schema.ref(:GroupResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    case is_admin?(conn) do
      true ->
        group = Accounts.get_group!(id)
        render(conn, "show.json", group: group)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :update do
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
    case is_admin?(conn) do
      true ->
        group = Accounts.get_group!(id)

        with {:ok, %Group{} = group} <- Accounts.update_group(group, group_params) do
          render(conn, "show.json", group: group)
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :delete do
    description "Delete Group"
    produces "application/json"
    parameters do
      id :path, :integer, "Group ID", required: true
    end
    response 204, ""
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    case is_admin?(conn) do
      true ->
        group = Accounts.get_group!(id)
        with {:ok, %Group{}} <- Accounts.delete_group(group) do
          send_resp(conn, :no_content, "")
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :user_groups do
    description "User Groups"
    parameters do
      id :path, :integer, "User ID", required: true
    end
    response 200, "OK", Schema.ref(:GroupsResponseData)
  end

  def user_groups(conn, %{"user_id" => user_id}) do
    case is_admin?(conn) do
      true ->
        user =
          user_id
          |> Accounts.get_user!()
          |> Repo.preload(:groups)
        render(conn, "index.json", groups: user.groups)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :add_groups_to_user do
    description "Add groups to users"
    produces "application/json"
    parameters do
      groups :body, Schema.ref(:GroupsCreate), "Groups create attrs"
      user_id :path, :integer, "User ID", required: true
    end
    response 201, "Created", Schema.ref(:GroupsResponseData)
    response 400, "Client Error"
  end

  def add_groups_to_user(conn, %{"user_id" => user_id, "groups" => groups}) do
    case is_admin?(conn) do
      true ->
        user =
          user_id
          |> Accounts.get_user!()
        with {:ok, %User{} = updateduser} <- Accounts.add_groups_to_user(user, groups) do
          conn
          |> put_status(:created)
          |> render("index.json", groups: updateduser.groups)
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :delete_user_groups do
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
    case is_admin?(conn) do
      true ->
        user =
          user_id
          |> Accounts.get_user!()
          |> Repo.preload(:groups)
        group = Accounts.get_group!(group_id)
        with {:ok, %User{}} <- Accounts.delete_group_from_user(user, group) do
          send_resp(conn, :no_content, "")
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  def search(conn, %{"data" => %{"ids" => ids}}) do
    case is_admin?(conn) do
      true ->
        groups =
          ids
          |> Accounts.list_groups()
        render(conn, "index.json", groups: groups)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end
  def search(conn, %{"data" => _}) do
    conn
    |> send_resp(:unprocessable_entity, "")
  end

  defp is_admin?(conn) do
    current_resource = conn.assigns[:current_resource]
    current_resource.is_admin
  end
end
