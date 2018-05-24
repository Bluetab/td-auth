defmodule TdAuthWeb.UserController do
  require Logger
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias Guardian.Plug
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuthWeb.SwaggerDefinitions
  alias TdAuthWeb.ErrorView
  alias TdAuth.Repo
  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.user_swagger_definitions()
  end

  swagger_path :index do
    get "/users"
    description "List Users"
    response 200, "OK", Schema.ref(:UsersResponseData)
  end

  def index(conn, _params) do
    case is_admin?(conn) do
      true ->
        users = Accounts.list_users() |> Repo.preload(:groups)
        render(conn, "index.json", users: users)
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")
    end
  end

  swagger_path :create do
    post "/users"
    description "Creates a User"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:UserCreate), "User create attrs"
    end
    response 201, "Created", Schema.ref(:UserResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"user" => user_params}) do
    case is_admin?(conn) do
      true ->
        conn
          |> do_create(user_params)
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")
    end
  end

  swagger_path :show do
    get "/users/{id}"
    description "Show User"
    produces "application/json"
    parameters do
      id :path, :integer, "User ID", required: true
    end
    response 200, "OK", Schema.ref(:UserResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    case is_admin?(conn) do
      true ->
        user =
          id
          |> Accounts.get_user!()
          |> Repo.preload(:groups)
        render(conn, "show.json", user: user)
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, "401.json")
    end
  end

  swagger_path :update do
    put "/users/{id}"
    description "Updates User"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:UserUpdate), "User update attrs"
      id :path, :integer, "User ID", required: true
    end
    response 200, "OK", Schema.ref(:UserResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "user" => %{"password" => _password} = user_params}) do
    current_user = Plug.current_resource(conn)
    update?(conn, id, user_params, current_user.is_admin)
  end
  def update(conn, %{"id" => id, "user" => user_params}) do
    current_user = Plug.current_resource(conn)
    update?(conn, id, user_params, current_user.is_admin || current_user.id == String.to_integer(id))
  end

  swagger_path :delete do
    delete "/users/{id}"
    description "Delete User"
    produces "application/json"
    parameters do
      id :path, :integer, "User ID", required: true
    end
    response 200, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    case is_admin?(conn) do
      true ->
        conn
        |> do_delete(id)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
    end
  end

  swagger_path :change_password do
    patch "/users/{id}/change_password"
    description "Updates User password"
    produces "application/json"
    parameters do
      id :path, :integer, "User ID", required: true
      user :body, Schema.ref(:UserChangePassword), "User change password attrs"
    end
    response 200, "OK"
    response 400, "Client Error"
  end

  def change_password(conn, %{"user_id" => id, "new_password" => new_password,
                                          "old_password" => old_password}) do
    with {:ok, user} <- check_user_conn(conn, id),
         true <- User.check_password(user, old_password),
         {:ok, %User{} = _user} <- Accounts.update_user(user, %{password: new_password})
    do
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
        |> put_status(:unauthorized)
        |> render(ErrorView, "401.json")
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
    with  {:ok, %User{} = user} <- create_user(user_params)
    do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user |> Repo.preload(:groups))

    else
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect("Inspect While creating user... #{inspect(changeset)}")
        IO.puts("Puts While creating user... #{inspect(changeset)}")
        Logger.error("Logger While creating user... #{inspect(changeset)}")
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdAuthWeb.ChangesetView, "error.json", changeset: changeset)
      error ->
        IO.inspect("Inspect While creating user... #{inspect(error)}")
        IO.puts("Puts While creating user... #{inspect(error)}")
        Logger.error("Logger While creating user... #{inspect(error)}")
        conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, "422.json")
    end

  end

  defp do_delete(conn, id) do
    user = Accounts.get_user!(id)
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end

  defp check_user_conn(conn, user_id) do
    user_conn = get_current_user(conn)
    case Accounts.get_user!(user_id) == user_conn  do
      true -> {:ok, user_conn}
      false -> {:error, "You are not the user conn"}
    end
  end

  defp update?(conn, id, user_params, true), do: do_update(conn, id, user_params)
  defp update?(conn, _id, _user_params, _) do
    conn
    |> put_status(:unauthorized)
    |> render(ErrorView, "401.json")
  end

  defp do_update(conn, id, user_params) do
    user = Accounts.get_user!(id)
    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user |> Repo.preload(:groups))
    end
  end

  defp is_admin?(conn) do
    current_user = Plug.current_resource(conn)
    current_user.is_admin
  end

end
