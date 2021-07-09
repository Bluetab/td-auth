defmodule TdAuthWeb.UserController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Claims
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.user_swagger_definitions()
  end

  swagger_path :index do
    description("List Users")
    response(200, "OK", Schema.ref(:UsersResponseData))
  end

  def index(conn, _params) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(current_resource, view(User))},
         users <- Accounts.list_users(preload: :groups) do
      render(conn, "index.json", users: users)
    end
  end

  swagger_path :create do
    description("Creates a User")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:UserCreate), "User create attrs")
    end

    response(201, "Created", Schema.ref(:UserResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"user" => user_params}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)} do
      do_create(conn, user_params)
    end
  end

  swagger_path :init do
    description("Creates initial admin user if no users exist")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:UserCreate), "User create attrs")
    end

    response(
      201,
      "Created",
      Schema.new do
        properties do
          user_name(:string, "Username", required: false)
          password(:object, "Password", required: false)
        end
      end
    )

    response(403, "Forbidden")
  end

  def can_init(conn, _params) do
    can_init = !Accounts.user_exists?()
    send_resp(conn, 200, Jason.encode!(can_init))
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

  swagger_path :show do
    description("Show User")
    produces("application/json")

    parameters do
      id(:path, :integer, "User ID", required: true)
    end

    response(200, "OK", Schema.ref(:UserResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    alias TdAuth.Permissions.UserAclMapper

    with {:can, true} <- {:can, Claims.is_admin?(conn)},
         user <- Accounts.get_user!(id, preload: :groups) do
      acls =
        user
        |> Accounts.get_user_acls()
        |> Enum.map(&UserAclMapper.map/1)

      render(conn, "show.json", user: user, acls: acls)
    end
  end

  swagger_path :update do
    description("Updates User")
    produces("application/json")

    parameters do
      user(:body, Schema.ref(:UserUpdate), "User update attrs")
      id(:path, :integer, "User ID", required: true)
    end

    response(200, "OK", Schema.ref(:UserResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"user" => %{"password" => _password}}) do
    conn
    |> put_status(:forbidden)
    |> put_view(ErrorView)
    |> render("403.json")
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    %{user_id: user_id} = conn.assigns[:current_resource]

    with {:can, true} <- {:can, Claims.is_admin?(conn) || id == "#{user_id}"},
         user <- Accounts.get_user!(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  swagger_path :delete do
    description("Delete User")
    produces("application/json")

    parameters do
      id(:path, :integer, "User ID", required: true)
    end

    response(200, "OK")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    with {:can, true} <- {:can, Claims.is_admin?(conn)},
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
