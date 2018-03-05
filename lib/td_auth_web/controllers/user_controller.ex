defmodule TdAuthWeb.UserController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias Guardian.Plug
  alias TdAuth.Auth.Guardian.Plug, as: GuardianPlug
  alias TdAuthWeb.SwaggerDefinitions
  alias TdAuthWeb.ErrorView
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
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  defp create_user(user_params) do
    Accounts.create_user(user_params)
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
    current_user = Plug.current_resource(conn)
    case current_user.is_admin do
      true ->
        conn
          |> do_create(user_params)
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, :"401.json")
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
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
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

  def update(conn, %{"id" => id, "user" => user_params}) do
    current_user = Plug.current_resource(conn)
    case current_user.is_admin do
      true ->
        conn
        |> do_update(id, user_params)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, :"401.json")
    end
  end

  defp do_update(conn, id, user_params) do
    user = Accounts.get_user!(id)
    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
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
    current_user = Plug.current_resource(conn)
    case current_user.is_admin do
      true ->
        conn
        |> do_delete(id)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, :"401.json")
    end
  end

  defp do_delete(conn, id) do
    user = Accounts.get_user!(id)
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :change_password do
    put "/users"
    description "Updates User password"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:UserChangePassword), "User change password attrs"
    end
    response 200, "OK"
    response 400, "Client Error"
  end

  def change_password(conn, %{"new_password" => new_password,
                              "old_password" => old_password}) do
    user = get_current_user(conn)
    case User.check_password(user, old_password) do
      true ->
        conn
          |> do_change_password(user, new_password)
      _ ->
        conn
          |> send_resp(:unprocessable_entity, "")
    end
  end

  defp do_create(conn, user_params) do
    with  {:ok, %User{} = user} <- create_user(user_params)
    do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)

    else
      _error ->
        conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, :"422.json")
    end

  end

  defp do_change_password(conn, user, new_password) do
    with {:ok, %User{} = _user} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :ok, "")
    else
      _error ->
        conn
          |> send_resp(:unprocessable_entity, "")
    end
  end

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end
end
