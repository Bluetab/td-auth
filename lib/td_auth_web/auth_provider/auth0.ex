defmodule TdAuthWeb.AuthProvider.Auth0 do
  @moduledoc false

  alias Plug.Conn
  alias TdAuthWeb.AuthProvider.CustomProfileMapping
  alias TdCache.NonceCache

  def authenticate(conn) do
    with {:ok, auth0_access_token} <- bearer_token(conn),
         {:ok, profile} <- get_auth0_profile(auth0_access_token) do
      {:ok, profile}
    else
      :error -> {:error, :no_access_token_found}
      {:error, e} -> {:error, e}
    end
  end

  def auth0_config(config) do
    %{
      domain: config[:domain],
      clientID: config[:client_id],
      redirectUri: config[:redirect_uri],
      audience: Enum.join([config[:audience], config[:userinfo]], ""),
      responseType: config[:response_type],
      scope: config[:scope],
      connection: config[:connection],
      state: NonceCache.create_nonce(),
      nonce: NonceCache.create_nonce()
    }
  end

  defp get_auth0_profile_path do
    auth = Application.get_env(:td_auth, :auth0)
    "#{auth[:protocol]}://#{auth[:domain]}#{auth[:userinfo]}"
  end

  defp get_auth0_profile_mapping do
    auth = Application.get_env(:td_auth, :auth0)
    auth[:profile_mapping]
  end

  defp get_auth0_profile(auth0_access_token) do
    headers = %{
      "Content-Type" => "application/json",
      "Accept" => "Application/json; Charset=utf-8",
      "Authorization" => "Bearer #{auth0_access_token}"
    }

    with {200, user_info} <- auth0_service().get_user_info(get_auth0_profile_path(), headers),
         {:ok, claims} <- Jason.decode(user_info),
         mapping <- get_auth0_profile_mapping() do
      CustomProfileMapping.map_profile(mapping, claims)
    else
      _ -> {:error, :unable_to_get_user_profile}
    end
  end

  defp auth0_service do
    Application.get_env(:td_auth, :auth0)[:auth0_service]
  end

  # Obtains a bearer token from request headers
  @spec bearer_token(Conn.t()) :: {:ok, binary()} | :error
  defp bearer_token(%Conn{} = conn) do
    conn
    |> Conn.get_req_header("authorization")
    |> Enum.filter(&String.starts_with?(&1, "Bearer "))
    |> Enum.map(&String.replace_leading(&1, "Bearer ", ""))
    |> Enum.fetch(0)
  end
end
