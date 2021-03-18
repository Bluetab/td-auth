defmodule TdAuthWeb.AuthProvider.OIDC do
  @moduledoc """
  Authentication provider for OpenID Connect
  """

  alias Plug.Conn
  alias TdAuthWeb.AuthProvider.CustomProfileMapping
  alias TdAuthWeb.AuthProvider.DefaultProfileMapping
  alias TdCache.NonceCache

  require Logger

  def authentication_url do
    verifier = create_code_verifier()
    nonce = NonceCache.create_nonce()
    state = NonceCache.create_nonce(verifier)

    params =
      code_challenge_method()
      |> auth_params(verifier)
      |> Map.put("nonce", nonce)
      |> Map.put("state", state)

    OpenIDConnect.authorization_uri(:oidc, params)
  end

  defp auth_params("S256", verifier) do
    challenge =
      :sha256
      |> :crypto.hash(verifier)
      |> Base.url_encode64()
      |> String.replace_suffix("=", "")

    %{
      "code_challenge" => challenge,
      "code_challenge_method" => "S256"
    }
  end

  defp auth_params(_, _), do: %{}

  defp code_challenge_method do
    :td_auth
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:code_challenge_method)
  end

  @spec authenticate(Conn.t() | map()) :: {:ok, map()} | {:error, any()} | :error
  def authenticate(conn_or_params)

  def authenticate(%Conn{} = conn) do
    with {:ok, token} <- bearer_token(conn),
         {:ok, claims} <- OpenIDConnect.verify(:oidc, token),
         {:ok, profile} <- map_profile(claims) do
      {:ok, profile}
    end
  end

  def authenticate(%{"code" => _code, "state" => state} = params) do
    with {:ok, verifier} <- validate_nonce(state),
         params <- verification_params(params, verifier),
         {:ok, %{"id_token" => token}} <- OpenIDConnect.fetch_tokens(:oidc, params),
         {:ok, claims} <- OpenIDConnect.verify(:oidc, token),
         {:ok, _} <- validate_nonce(claims),
         {:ok, profile} <- map_profile(claims) do
      {:ok, profile}
    end
  end

  defp verification_params(params, ""), do: params
  defp verification_params(params, verifier), do: Map.put(params, "code_verifier", verifier)

  @spec validate_nonce(map() | binary() | nil) :: {:ok, binary()} | {:error, :invalid_nonce}
  defp validate_nonce(%{"nonce" => nonce} = _claims), do: validate_nonce(nonce)

  defp validate_nonce(nonce) when is_binary(nonce) do
    case NonceCache.pop(nonce) do
      nil -> {:error, :invalid_nonce}
      value -> {:ok, value}
    end
  end

  defp validate_nonce(_map_or_nil), do: {:error, :invalid_nonce}

  defp map_profile(claims) do
    :td_auth
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:profile_mapping)
    |> case do
      %{} = mapping ->
        CustomProfileMapping.map_profile(mapping, claims)

      mapping when is_binary(mapping) ->
        mapping |> Jason.decode!() |> CustomProfileMapping.map_profile(claims)

      nil ->
        DefaultProfileMapping.map_profile(claims)
    end
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

  # Creates a PKCE code verifier
  defp create_code_verifier do
    length =
      :td_auth
      |> Application.get_env(__MODULE__, [])
      |> Keyword.get(:code_verifier_length, 128)

    NonceCache.create_nonce("", length, 1)
  end
end
