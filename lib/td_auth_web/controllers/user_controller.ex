defmodule TdAuthWeb.UserController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Repo
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

    with {:can, true} <- {:can, can?(current_resource, list(User))},
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
    with {:can, true} <- {:can, is_admin?(conn)} do
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

  def init(conn, %{"user" => user_params}) do
    if Accounts.user_exists?() do
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    else
      user_params =
        user_params
        |> Map.put("is_admin", true)
        |> Map.put("is_protected", true)

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
    with {:can, true} <- {:can, is_admin?(conn)},
         user <- Accounts.get_user!(id, preload: :groups) do
      acls =
        user
        |> Accounts.get_user_acls()
        |> Enum.map(&TdAuth.Permissions.UserAclMapper.map/1)

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

  def update(conn, %{"id" => id, "user" => %{"password" => _password} = user_params}) do
    current_resource = conn.assigns[:current_resource]

    with {:can, true} <- {:can, current_resource.is_admin},
         user <- Accounts.get_user!(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: Repo.preload(user, :groups))
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    %{is_admin: is_admin, id: current_id} = conn.assigns[:current_resource]

    with {:can, true} <- {:can, is_admin || id == "#{current_id}"},
         user <- Accounts.get_user!(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: Repo.preload(user, :groups))
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
    with {:can, true} <- {:can, is_admin?(conn)},
         user <- Accounts.get_user!(id),
         {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :change_password do
    description("Updates User password")
    produces("application/json")

    parameters do
      id(:path, :integer, "User ID", required: true)
      user(:body, Schema.ref(:UserChangePassword), "User change password attrs")
    end

    response(200, "OK")
    response(400, "Client Error")
  end

  def change_password(conn, %{
        "user_id" => id,
        "new_password" => new_password,
        "old_password" => old_password
      }) do
    with {:ok, user} <- check_user_conn(conn, id),
         {:ok, user} <- User.check_password(user, old_password),
         {:ok, %User{} = _user} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :ok, "")
    else
      _error ->
        conn
        |> send_resp(:unprocessable_entity, "")
    end
  end

  swagger_path :update_password do
    description("Updates User password without the old password")
    produces("application/json")

    parameters do
      new_password(:body, Schema.ref(:UserUpdatePassword), "User change password attrs")
    end

    response(200, "OK")
    response(400, "Client Error")
  end

  def update_password(conn, %{"new_password" => new_password}) do
    user = conn.assigns[:current_resource]

    user = Accounts.get_user!(user.id, preload: :groups)

    with true <- new_password != "",
         {:ok, %User{} = _user1} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :no_content, "")
    else
      _error ->
        conn
        |> send_resp(:unprocessable_entity, "")
    end
  end

  defp do_create(conn, user_params) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json", user: Repo.preload(user, :groups))
    end
  end

  defp check_user_conn(conn, user_id) do
    %{id: id} = conn.assigns[:current_resource]

    case id == String.to_integer(user_id) do
      true -> {:ok, Accounts.get_user!(id)}
      false -> {:error, "You are not the user conn"}
    end
  end

  defp is_admin?(conn) do
    current_resource = conn.assigns[:current_resource]
    current_resource.is_admin
  end
end
