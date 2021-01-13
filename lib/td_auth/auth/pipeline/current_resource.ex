defmodule TdAuth.Auth.Pipeline.CurrentResource do
  @moduledoc """
  A plug to read the claims from Guardian and assign them to the :current_resource
  key in the connection.
  """

  use Plug.Builder

  plug(:current_resource)

  def init(opts), do: opts

  def current_resource(conn, _opts) do
    claims = Guardian.Plug.current_resource(conn)
    assign(conn, :current_resource, claims)
  end
end
