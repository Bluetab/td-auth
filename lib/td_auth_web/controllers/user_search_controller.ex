defmodule TdAuthWeb.UserSearchController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback TdAuthWeb.FallbackController

  @max_results Application.compile_env(:td_auth, TdAuthWeb.UserSearchController)[:max_results]

  def swagger_definitions do
    SwaggerDefinitions.user_swagger_definitions()
  end

  swagger_path :create do
    description("Search Users")
    response(200, "OK", Schema.ref(:UsersSearchResponseData))
  end

  def create(conn, params) do
    query = "%" <> Map.get(params, "query", "") <> "%"
    users = Accounts.list_users(limit: @max_results, query: query)

    conn
    |> put_view(TdAuthWeb.UserView)
    |> render("search.json", users: users)
  end
end
