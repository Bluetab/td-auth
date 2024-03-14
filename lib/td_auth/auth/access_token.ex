defmodule TdAuth.Auth.AccessToken do
  @moduledoc """
  Joken config module for Truedat JWT access tokens
  """

  use Joken.Config

  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Claims
  alias TdAuth.Permissions

  @impl true
  def token_config do
    exp = expiry()
    default_claims(aud: "truedat", iss: "tdauth", default_exp: exp)
  end

  @spec new(User.t(), map() | binary() | nil) :: {:ok, map()} | {:error, Joken.error_reason()}
  def new(%User{} = user, auth_method_or_claims) do
    default_permissions = Permissions.default_permissions()
    user_permissions = Permissions.user_permissions(user)

    uniq_user_permissions =
      user_permissions |> Map.values() |> Enum.flat_map(&Map.keys(&1)) |> Enum.uniq()

    permission_groups = permission_groups(user, uniq_user_permissions ++ default_permissions)
    {:ok, claims} = claims(user, permission_groups, auth_method_or_claims)

    case encode_and_sign(claims) do
      {:ok, token, claims} ->
        {:ok, %{token: token, claims: claims, permissions: user_permissions}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec resource_from_claims(map) :: {:ok, TdAuth.Auth.Claims.t()}
  def resource_from_claims(%{"sub" => sub} = claims) do
    case Jason.decode(sub) do
      {:ok, %{"id" => id, "user_name" => user_name}} ->
        role = Map.get(claims, "role")

        resource = %Claims{
          user_id: id,
          user_name: user_name,
          role: role,
          jti: claims["jti"]
        }

        {:ok, resource}

      error ->
        error
    end
  end

  defp claims(%{role: role, user_name: user_name} = user, groups, auth_method_or_claims) do
    %{
      "role" => to_string(role),
      "groups" => groups,
      "sub" => sub(user),
      "user_name" => user_name
    }
    |> maybe_put_amr(auth_method_or_claims)
    |> maybe_put_entitlements(role, groups)
    |> generate_claims()
  end

  defp sub(%{id: user_id, user_name: user_name} = _user) do
    Jason.encode!(%{"id" => user_id, "user_name" => user_name})
  end

  defp maybe_put_amr(claims, %{"amr" => ["pwd"]} = _prev_claims),
    do: Map.put(claims, "amr", ["pwd"])

  defp maybe_put_amr(claims, "pwd" = _auth_method),
    do: Map.put(claims, "amr", ["pwd"])

  defp maybe_put_amr(claims, _), do: claims

  defp maybe_put_entitlements(claims, role, groups)

  defp maybe_put_entitlements(claims, :admin, _), do: Map.put(claims, "entitlements", ["p"])

  defp maybe_put_entitlements(claims, _, [_ | _] = _groups),
    do: Map.put(claims, "entitlements", ["p"])

  defp maybe_put_entitlements(claims, _not_admin, _no_groups), do: claims

  defp permission_groups(%{role: :admin}, _permissions), do: []

  defp permission_groups(_user, permissions) when is_list(permissions) do
    Permissions.group_names(permissions)
  end

  def expiry do
    :td_auth
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:ttl_seconds)
  end
end
