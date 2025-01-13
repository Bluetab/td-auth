defmodule TdAuthWeb.GroupSearchController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts

  require Logger

  action_fallback TdAuthWeb.FallbackController

  @max_results Application.compile_env(:td_auth, TdAuthWeb.GroupSearchController)[:max_results]

  def create(conn, params) do
    query = "%" <> Map.get(params, "query", "") <> "%"
    groups = Accounts.list_groups(limit: @max_results, query: query, preload: :users)

    conn
    |> put_view(TdAuthWeb.GroupView)
    |> render("search.json", groups: groups)
  end
end
