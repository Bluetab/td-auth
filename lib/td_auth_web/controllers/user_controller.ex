defmodule TdAuthWeb.UserController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Claims
  alias TdAuthWeb.ErrorView

  require Logger

  action_fallback TdAuthWeb.FallbackController

  def index(conn, _params) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(current_resource, view(User))},
         users <- Accounts.list_users(preload: :groups) do
      render(conn, "index.json", users: users)
    end
  end

  def agents(conn, _params) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(current_resource, view(User))},
         users <- Accounts.list_users(role: :agent, preload: :groups) do
      render(conn, "index.json", users: users)
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:can, true} <- {:can, Claims.admin?(conn)} do
      do_create(conn, user_params)
    end
  end

  def can_init(conn, _params) do
    can_init = !Accounts.user_exists?()

    render(conn, "can_init.json", can_init: can_init)
  end

  def init(conn, %{"user" => user_params}) do
    if Accounts.user_exists?() do
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    else
      user_params = Map.put(user_params, "role", "admin")
      do_create(conn, user_params)
    end
  end

  def show(conn, %{"id" => id}) do
    alias TdAuth.Permissions.UserAclMapper

    with {:can, true} <- {:can, Claims.admin?(conn)},
         user <- Accounts.get_user!(id, preload: :groups) do
      acls =
        user
        |> Accounts.get_user_acls()
        |> Enum.map(&UserAclMapper.map/1)

      render(conn, "show.json", user: user, acls: acls)
    end
  end

  def update(conn, %{"user" => %{"password" => _password}}) do
    conn
    |> put_status(:forbidden)
    |> put_view(ErrorView)
    |> render("403.json")
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    %{user_id: user_id} = conn.assigns[:current_resource]

    with {:can, true} <- {:can, Claims.admin?(conn) || id == "#{user_id}"},
         user <- Accounts.get_user!(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:can, true} <- {:can, Claims.admin?(conn)},
         user <- Accounts.get_user!(id),
         {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  defp do_create(conn, user_params) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end
end
