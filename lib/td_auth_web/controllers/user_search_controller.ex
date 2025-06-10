defmodule TdAuthWeb.UserSearchController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Accounts

  alias TdCache.Permissions
  alias TdCache.TaxonomyCache

  require Logger

  action_fallback TdAuthWeb.FallbackController

  @max_results Application.compile_env(:td_auth, TdAuthWeb.UserSearchController)[:max_results]

  def create(conn, params) do
    claims = conn.assigns[:current_resource]

    criteria =
      [limit: @max_results]
      |> maybe_with_query(params)
      |> maybe_with_domains(params)
      |> maybe_with_any_domain_roles(params)
      |> maybe_with_permission_on_domains(params, claims)

    users = Accounts.list_users(criteria)

    conn
    |> put_view(TdAuthWeb.UserView)
    |> render("search.json", users: users)
  end

  def grant_requestable(conn, params) do
    %{user_id: user_id} = claims = conn.assigns[:current_resource]
    params = Map.take(params, ["structures_domains", "filter_domains", "query", "roles"])
    domain_ids = Map.get(params, "structures_domains", [])

    with {:can, true} <- {:can, can?(claims, in_any_domain(:view_data_structure))},
         {:can, true} <- {:can, can?(claims, in_any_domain(:create_foreign_grant_request))},
         {:valid_params, %{"structures_domains" => [_ | _]}} <- {:valid_params, params},
         {:can_every_domain, true} <-
           {:can_every_domain,
            can?(
              claims,
              in_every_domain(%{
                permission: :create_foreign_grant_request,
                domains: domain_ids
              })
            )} do
      users = Accounts.get_requestable_users(user_id, params)

      rende_users(conn, users)
    else
      {type, _} when type in [:valid_params, :can_every_domain] ->
        rende_users(conn, [])

      error ->
        error
    end
  end

  defp rende_users(conn, users) do
    conn
    |> put_view(TdAuthWeb.UserView)
    |> render("search.json", users: users)
  end

  defp maybe_with_query(criteria, %{"query" => query}), do: criteria ++ [query: "%#{query}%"]
  defp maybe_with_query(criteria, _), do: criteria

  defp maybe_with_domains(criteria, %{"domains" => domains}),
    do: criteria ++ [domains: Enum.map(domains, &String.to_integer(&1))]

  defp maybe_with_domains(criteria, _), do: criteria

  defp maybe_with_any_domain_roles(criteria, %{"roles" => roles}), do: criteria ++ [roles: roles]

  defp maybe_with_any_domain_roles(criteria, _), do: criteria

  defp maybe_with_permission_on_domains(criteria, %{"permission" => permission}, claims) do
    domain_ids = permitted_domain_ids(claims, permission)
    criteria ++ [permission_on_domains: {permission, domain_ids}]
  end

  defp maybe_with_permission_on_domains(criteria, _, _), do: criteria

  defp permitted_domain_ids(%{role: role}, _action) when role in ["admin", "service"] do
    TaxonomyCache.reachable_domain_ids(0)
  end

  defp permitted_domain_ids(%{role: "user", jti: jti}, "allow_foreign_grant_request"),
    do: Permissions.permitted_domain_ids(jti, :create_foreign_grant_request)

  defp permitted_domain_ids(_claims, _action), do: []
end
