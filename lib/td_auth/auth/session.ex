defmodule TdAuth.Auth.Session do
  @moduledoc """
  A struct for storing session-related data
  """
  defstruct [:jti, :id, :user_name, :is_admin, :exp, :groups]
end
