defmodule TdAuth.Auth.Pipeline.Secure do
  @moduledoc """
  Plug pipeline to validate access token in request headers
  """

  use Plug.Builder

  alias TdAuth.Auth.AccessToken
  alias TdAuth.Auth.ErrorHandler
  alias TdCache.SessionCache

  plug :authenticate

  def init(opts), do: opts

  def authenticate(conn, _opts) do
    with token when is_binary(token) <- token_from_headers(conn),
         {:ok, claims} <- AccessToken.verify_and_validate(token),
         {:ok, %{jti: jti} = resource} <- AccessToken.resource_from_claims(claims),
         true <- SessionCache.exists?(jti) do
      conn
      |> assign(:current_token, token)
      |> assign(:current_resource, resource)
    else
      _ -> ErrorHandler.unauthorized(conn)
    end
  end

  defp token_from_headers(conn) do
    conn
    |> get_req_header("authorization")
    |> Enum.filter(&String.starts_with?(&1, "Bearer "))
    |> Enum.map(fn "Bearer " <> token -> token end)
    |> Enum.at(0)
  end
end
