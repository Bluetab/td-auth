defmodule TdAuth.Sessions do
  @moduledoc """
  The sessions context.
  """

  alias TdAuth.Accounts
  alias TdAuth.Auth.AccessToken
  alias TdAuth.Auth.RefreshToken
  alias TdAuth.Permissions
  alias TdCache.SessionCache

  def create(%{} = user, auth_method) do
    with {:ok, access_token, claims, user_permissions} <- AccessToken.new(user, auth_method),
         {:ok, refresh_token, refresh_claims} <- create_refresh_token(claims),
         :ok <- SessionCache.put(claims),
         :ok <- SessionCache.put(refresh_claims),
         %{"jti" => jti, "exp" => exp} <- claims do
      Permissions.cache_session_permissions(user_permissions, jti, exp)
      {:ok, %{token: access_token, refresh_token: refresh_token, claims: claims}}
    end
  end

  def refresh(refresh_token, access_token) do
    with {:ok, %{"sub" => jti, "jti" => refresh_jti, "exp" => exp}} <-
           RefreshToken.verify_and_validate(refresh_token),
         {:ok, %{"jti" => ^jti, "sub" => sub} = prev_claims} <-
           AccessToken.verify_and_validate(access_token),
         {:ok, %{"id" => user_id}} <- Jason.decode(sub),
         user <- Accounts.get_user!(user_id),
         {:ok, access_token, claims, user_permissions} <- AccessToken.new(user, prev_claims),
         {:ok, refresh_token, %{} = refresh_claims} <- create_refresh_token(claims, exp),
         :ok <- SessionCache.delete(jti),
         :ok <- SessionCache.delete(refresh_jti),
         :ok <- SessionCache.put(claims),
         :ok <- SessionCache.put(refresh_claims),
         %{"jti" => jti, "exp" => exp} <- claims do
      Permissions.cache_session_permissions(user_permissions, jti, exp)
      {:ok, %{token: access_token, refresh_token: refresh_token, claims: claims}}
    end
  end

  def delete(refresh_token, access_token) do
    maybe_delete_token(refresh_token, &RefreshToken.verify/1)
    maybe_delete_token(access_token, &AccessToken.verify/1)
  end

  defp maybe_delete_token({:ok, %{"jti" => jti}}, _verify), do: SessionCache.delete(jti)

  defp maybe_delete_token(token, verify_fun) when is_binary(token) do
    token
    |> verify_fun.()
    |> maybe_delete_token(verify_fun)
  end

  defp maybe_delete_token(_other, _verify), do: :ok

  defp create_refresh_token(claims, exp \\ nil)

  defp create_refresh_token(%{"jti" => jti} = _claims, nil) do
    {:ok, claims} = RefreshToken.generate_claims(%{"sub" => jti})
    RefreshToken.encode_and_sign(claims)
  end

  defp create_refresh_token(%{"jti" => jti} = _claims, exp) do
    {:ok, claims} = RefreshToken.generate_claims(%{"sub" => jti, "exp" => exp})
    RefreshToken.encode_and_sign(claims)
  end
end
