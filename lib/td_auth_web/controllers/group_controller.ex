defmodule TdAuthWeb.GroupController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Auth.Claims

  action_fallback TdAuthWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(Group))},
         groups <- Accounts.list_groups(preload: :users) do
      render(conn, "index.json", groups: groups)
    end
  end

  def create(conn, %{"group" => group_params}) do
    with {:can, true} <- {:can, Claims.admin?(conn)},
         {:ok, %Group{} = group} <- Accounts.create_group(group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.group_path(conn, :show, group))
      |> render("show.json", group: group)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:can, true} <- {:can, Claims.admin?(conn)},
         group <- Accounts.get_group!(id, preload: :users) do
      render(conn, "show.json", group: group)
    end
  end

  def update(conn, %{"id" => id, "group" => group_params}) do
    with {:can, true} <- {:can, Claims.admin?(conn)},
         group <- Accounts.get_group!(id, preload: :users),
         {:ok, %Group{} = group} <- Accounts.update_group(group, group_params) do
      render(conn, "show.json", group: group)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:can, true} <- {:can, Claims.admin?(conn)},
         group <- Accounts.get_group!(id),
         {:ok, %Group{}} <- Accounts.delete_group(group) do
      send_resp(conn, :no_content, "")
    end
  end
end
