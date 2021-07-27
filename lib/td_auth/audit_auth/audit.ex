defmodule TdAuth.AuditAuth.Audit do
  @moduledoc """
  Manages the creation of audit events relating to Auth
  """

  import TdAuth.Audit.AuditSupport, only: [publish: 5]

  def login_attempt(access_method, user_name) do
    payload = %{
      "user_name" => user_name,
      "access_method" => access_method
    }

    publish("login_attempt", "auth", nil, nil, payload)
  end

  def login_success(access_method, user) do
    payload = %{
      "user_name" => user.user_name,
      "access_method" => access_method
    }

    publish("login_success", "auth", user.id, user.id, payload)
  end
end
