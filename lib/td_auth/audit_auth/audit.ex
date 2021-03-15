defmodule TdAuth.AuditAuth.Audit do
  @moduledoc """
  Manages the creation of audit events relating to Auth
  """

  import TdAuth.Audit.AuditSupport, only: [publish: 5]

  require Logger

  def login_attempt(access_method, user_name) do
    Logger.info("login_attempt access_method #{inspect(access_method)}")
    Logger.info("login_attempt user_name #{inspect(user_name)}")

    payload = %{
      "user_name" => user_name,
      "access_method" => access_method
    }
    Logger.info "login_attempt payload #{inspect payload}"
    result = publish("login_attempt", "auth", nil, nil, payload)
    Logger.info("login_attempt result #{inspect(result)}")
    result
  end

  def login_success(access_method, user) do
    Logger.info("login_success access_method #{inspect(access_method)}")
    Logger.info("login_success user #{inspect(user.id)}")

    payload = %{
      "user_name" => user.user_name,
      "access_method" => access_method
    }

    Logger.info("login_success payload #{inspect(payload)}")
    result = publish("login_success", "auth", user.id, user.id, payload)
    Logger.info("login_success result #{inspect(result)}")
    result
  end
end
