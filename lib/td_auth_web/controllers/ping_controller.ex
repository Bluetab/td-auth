defmodule TdAuthWeb.PingController do
  use TdAuthWeb, [:controller, :warn]

  action_fallback TdAuthWeb.FallbackController

  def ping(conn, _params) do
    send_resp(conn, 200, "pong")
  end
end
