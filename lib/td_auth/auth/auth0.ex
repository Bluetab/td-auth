defmodule TdAuth.Auth.Auth0 do
  @moduledoc false
  use Guardian, otp_app: :td_auth

  def subject_for_token(_resource, _claims) do
    {:ok, "unused"}
  end

  def resource_from_claims(claims) do
    {:ok, claims["sub"]}
  end
end
