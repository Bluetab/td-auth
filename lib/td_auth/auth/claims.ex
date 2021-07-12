defmodule TdAuth.Auth.Claims do
  @moduledoc """
  Jason web tokens (JWTs) contain claims which are pieces of information
  asserted about a subject. This module provides a struct containing the claims
  that are used by Truedat.
  """

  @typedoc "The claims of an authenticated user"
  @type t :: %__MODULE__{
          user_id: non_neg_integer() | nil,
          user_name: binary() | nil,
          role: binary() | nil,
          has_permissions: boolean(),
          groups: [binary()],
          jti: binary() | nil,
          access_method: binary() | nil
        }

  @derive {Jason.Encoder, only: [:user_id, :user_name]}
  defstruct [
    :user_id,
    :user_name,
    :role,
    :jti,
    :access_method,
    has_permissions: false,
    groups: []
  ]

  @spec is_admin?(Plug.Conn.t()) :: boolean
  def is_admin?(conn) do
    case conn.assigns[:current_resource] do
      %{role: "admin"} -> true
      _ -> false
    end
  end
end
