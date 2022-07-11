defmodule TdAuth.AuditAuth do
  @moduledoc """
  Audit for login attempt and created sessions
  """
  alias TdAuth.AuditAuth.Audit

  @doc """
  Publishes the corresponding audit attemp event
  """
  def attempt_event(access_method, %{"user" => %{"user_name" => user_name}} = _params) do
    Audit.login_attempt(access_method, user_name)
  end

  ## session event
  def session_event(access_method, user) do
    Audit.login_success(access_method, user)
  end
end
