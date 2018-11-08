defmodule TdAuthWeb.AuthProvider.OIDC do
  @moduledoc """
  Authentication provider for OpenID Connect
  """

  alias TdPerms.NonceCache
  require Logger

  def authentication_url do
    nonce = NonceCache.create_nonce
    state = NonceCache.create_nonce

    OpenIDConnect.authorization_uri(:oidc, %{
      "response_mode" => "fragment",
      "nonce" => nonce,
      "state" => state
    })
  end

  @doc """
  Authenticate a user using and OpenID Connect ID token
  """
  def authenticate(authorization_headers) do
    with {:ok, claims} <- verify_token(authorization_headers),
         profile <- map_profile(claims) do
      {:ok, profile}
    else
      error -> error
    end
  end

  @doc """
  Verifies an OpenID Connect token extracted from request headers
  """
  defp verify_token(authorization_headers) do
    authorization_headers
    |> extract_token
    |> verify
  end

  defp verify(token) do
    OpenIDConnect.verify(:oidc, token)
  end

  @doc """
  Extracts the Bearer token from an authorization header
  """
  defp extract_token(authorization_headers) do
    authorization_headers
    |> Enum.find(&String.starts_with?(&1, "Bearer "))
    |> String.replace_leading("Bearer ", "")
  end

  @doc """
  Maps Google OpenID Connect claims to a user profile
  """
  defp map_profile(%{"email" => email, "name" => full_name}) do
    %{user_name: email, full_name: full_name, email: email}
  end

  @doc """
  Maps an Azure OpenID Connect claims to a user profile
  """
  defp map_profile(%{"unique_name" => unique_name, "name" => full_name}) do
    %{user_name: unique_name, full_name: full_name, email: unique_name}
  end

  @doc """
  Logs a warning if no mapping is defined for the claims
  """
  defp map_profile(claims) do
    Logger.warn("No mapping defined for claims #{inspect(claims)}")
    {:error}
  end
end
