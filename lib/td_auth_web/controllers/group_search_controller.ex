defmodule TdAuthWeb.GroupSearchController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback TdAuthWeb.FallbackController

  @max_results Application.compile_env(:td_auth, TdAuthWeb.GroupSearchController)[:max_results]

  def swagger_definitions do
    SwaggerDefinitions.group_swagger_definitions()
  end

  swagger_path :create do
    description("Search Groups")
    response(200, "OK", Schema.ref(:GroupsResponseData))
  end

  def create(conn, params) do
    query = "%" <> Map.get(params, "query", "") <> "%"
    groups = Accounts.list_groups(limit: @max_results, query: query)

    conn
    |> put_view(TdAuthWeb.GroupView)
    |> render("index.json", groups: groups)
  end
end
