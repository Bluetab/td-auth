defmodule TdAuthWeb.UserController do
  require Logger
  use TdAuthWeb, :controller
  use PhoenixSwagger

  import Canada

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Accounts.UserAcl
  alias TdAuth.Repo
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions

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

    case current_resource |> can?(list(User)) do
      true ->
        users = Accounts.list_users() |> Repo.preload(:groups)
        render(conn, "index.json", users: users)

      _ ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
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
    case is_admin?(conn) do
      true ->
        conn
        |> do_create(user_params)

      _ ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  end

  swagger_path :init do
    description("Creates initial admin user if no users exist")
    produces("application/json")

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
    case length(Accounts.list_users()) do
      0 ->
        user_params = Map.put(user_params, "is_admin", true)
        conn |> do_create(user_params)

      _ ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
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
    case is_admin?(conn) do
      true ->
        user =
          id
          |> Accounts.get_user!()
          |> Repo.preload(:groups)

        acls = UserAcl.get_user_acls(user)

        render(conn, "show.json", user: user, acls: acls)

      _ ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
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
    update?(conn, id, user_params, current_resource.is_admin)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    current_resource = conn.assigns[:current_resource]

    update?(
      conn,
      id,
      user_params,
      current_resource.is_admin || current_resource.id == String.to_integer(id)
    )
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
    case is_admin?(conn) do
      true ->
        conn
        |> do_delete(id)

      _ ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
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
         true <- User.check_password(user, old_password),
         {:ok, %User{} = _user} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :ok, "")
    else
      _error ->
        conn
        |> send_resp(:unprocessable_entity, "")
    end
  end

  def search(conn, %{"data" => %{"ids" => ids}}) do
    case is_admin?(conn) do
      true ->
        users =
          ids
          |> Accounts.list_users()
          |> Repo.preload(:groups)

        render(conn, "index.json", users: users)

      _ ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  end

  def search(conn, %{"data" => _}) do
    conn
    |> send_resp(:unprocessable_entity, "")
  end

  defp create_user(user_params) do
    Accounts.create_user(user_params)
  end

  defp do_create(conn, user_params) do
    with {:ok, %User{} = user} <- create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json", user: user |> Repo.preload(:groups))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(TdAuthWeb.ChangesetView)
        |> render("error.json", changeset: changeset)

      error ->
        Logger.error("Logger While creating user... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  defp do_delete(conn, id) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  defp check_user_conn(conn, user_id) do
    %{id: id} = conn.assigns[:current_resource]

    case id == String.to_integer(user_id) do
      true -> {:ok, Accounts.get_user!(id)}
      false -> {:error, "You are not the user conn"}
    end
  end

  defp update?(conn, id, user_params, true), do: do_update(conn, id, user_params)

  defp update?(conn, _id, _user_params, _) do
    conn
    |> put_status(:forbidden)
    |> put_view(ErrorView)
    |> render("403.json")
  end

  defp do_update(conn, id, user_params) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user |> Repo.preload(:groups))
    end
  end

  defp is_admin?(conn) do
    current_resource = conn.assigns[:current_resource]
    current_resource.is_admin
  end
end
