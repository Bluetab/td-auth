defmodule TdAuth.Auth.Guardian do
  @moduledoc "Guardian implementation module"

  use Guardian, otp_app: :td_auth

  alias TdAuth.Auth.Claims

  def subject_for_token(resource, _claims) do
    Jason.encode(resource)
  end

  def resource_from_claims(%{"sub" => sub} = claims) do
    %{"id" => id, "user_name" => user_name} = Jason.decode!(sub)
    role = Map.get(claims, "role")
    groups = Map.get(claims, "groups", [])

    resource = %Claims{
      user_id: id,
      user_name: user_name,
      role: role,
      groups: groups,
      jti: claims["jti"]
    }

    {:ok, resource}
  end
end
