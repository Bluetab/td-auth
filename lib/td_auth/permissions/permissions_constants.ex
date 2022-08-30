defmodule TdAuth.Permissions.Constants do
  @moduledoc """
  Permissions constants.
  """
  @custom_prefix "custom."

  @doc """
  External permission/permission group (also known as "custom"
  permission/permission group) prefix.
  Permissions and permission groups with this prefix will not be deleted
  ("obsoleted") by TdAuth.Permissions.Seeds
  """
  def custom_prefix, do: @custom_prefix
end
