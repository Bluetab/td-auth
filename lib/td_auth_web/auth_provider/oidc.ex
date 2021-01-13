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
    nonce = NonceCache.create_nonce()
    state = NonceCache.create_nonce()

    OpenIDConnect.authorization_uri(:oidc, %{
      # "response_mode" => "fragment",
      "nonce" => nonce,
      "state" => state
    })
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
    with :ok <- validate_nonce(state),
         {:ok, %{"id_token" => token}} <- OpenIDConnect.fetch_tokens(:oidc, params),
         {:ok, claims} <- OpenIDConnect.verify(:oidc, token),
         :ok <- validate_nonce(claims),
         {:ok, profile} <- map_profile(claims) do
      {:ok, profile}
    end
  end

  @spec validate_nonce(map() | binary() | nil) :: :ok | {:error, :invalid_nonce}
  defp validate_nonce(%{"nonce" => nonce} = _claims), do: validate_nonce(nonce)

  defp validate_nonce(nonce) when is_binary(nonce) do
    case NonceCache.pop(nonce) do
      nil -> {:error, :invalid_nonce}
      _ -> :ok
    end
  end

  defp validate_nonce(_map_or_nil), do: {:error, :invalid_nonce}

  defp map_profile(claims) do
    :td_auth
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:profile_mapping)
    |> case do
      %{} = mapping -> CustomProfileMapping.map_profile(mapping, claims)
      mapping when is_binary(mapping) -> mapping |> Jason.decode!() |> CustomProfileMapping.map_profile(claims)
      nil -> DefaultProfileMapping.map_profile(claims)
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
end
