defmodule TdAuth.Auth.Session do
  @moduledoc """
  A struct for storing session-related data
  """
  defstruct [:jti, :id, :user_name, :gids, :is_admin, :exp]
end
