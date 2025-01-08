defmodule TdAuthWeb.UserSearchController do
  use TdAuthWeb, :controller

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
