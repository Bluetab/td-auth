defmodule TdAuthWeb.Router do
  use TdAuthWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TdAuthWeb do
    pipe_through :api
  end
end
