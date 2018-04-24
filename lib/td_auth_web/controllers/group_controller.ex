defmodule TdAuthWeb.GroupController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Repo

  action_fallback TdAuthWeb.FallbackController

  def index(conn, _params) do
    groups = Accounts.list_groups()
    render(conn, "index.json", groups: groups)
  end

  def create(conn, %{"group" => group_params}) do
    with {:ok, %Group{} = group} <- Accounts.create_group(group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", group_path(conn, :show, group))
      |> render("show.json", group: group)
    end
  end

  def show(conn, %{"id" => id}) do
    group = Accounts.get_group!(id)
    render(conn, "show.json", group: group)
  end

  def update(conn, %{"id" => id, "group" => group_params}) do
    group = Accounts.get_group!(id)

    with {:ok, %Group{} = group} <- Accounts.update_group(group, group_params) do
      render(conn, "show.json", group: group)
    end
  end

  def delete(conn, %{"id" => id}) do
    group = Accounts.get_group!(id)
    with {:ok, %Group{}} <- Accounts.delete_group(group) do
      send_resp(conn, :no_content, "")
    end
  end

  def user_groups(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user!(user_id) |> Repo.preload(:groups)
    render(conn, "index.json", groups: user.groups)
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

  def delete_user_groups(conn, %{"user_id" => user_id, "id" => group_id}) do
    user = Accounts.get_user!(user_id) |> Repo.preload(:groups)
    group = Accounts.get_group!(group_id)
    with {:ok, %User{}} <- Accounts.delete_group_from_user(user, group) do
      send_resp(conn, :no_content, "")
    end
  end
end
