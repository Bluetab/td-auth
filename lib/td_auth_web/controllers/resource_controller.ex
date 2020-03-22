defmodule TdAuthWeb.ResourceController do
  @moduledoc """
  This controller is unused, but exists so hypermedia links can be generated to
  resources within other Truedat services.
  """
  use TdAuthWeb, :controller

  action_fallback(TdAuthWeb.FallbackController)
end
