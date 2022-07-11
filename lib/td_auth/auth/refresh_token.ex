defmodule TdAuth.Auth.RefreshToken do
  @moduledoc """
  Joken config module for Truedat JWT refresh tokens
  """

  use Joken.Config

  @impl true
  def token_config do
    exp = expiry()
    default_claims(aud: "tdauth", iss: "tdauth", default_exp: exp)
  end

  defp expiry do
    :td_auth
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:ttl_seconds)
  end
end
