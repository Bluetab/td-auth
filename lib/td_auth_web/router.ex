defmodule TdAuthWeb.Router do
  use TdAuthWeb, :router

  pipeline :api do
    plug TdAuth.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TdAuth.Auth.Pipeline.Secure
  end

  scope "/api", TdAuthWeb do
    pipe_through :api
    get "/ping", PingController, :ping
    post "/sessions", SessionController, :create
  end

  scope "/api", TdAuthWeb do
    pipe_through [:api, :api_secure]
    get "/sessions", SessionController, :ping
    delete "/sessions", SessionController, :destroy
    resources "/users", UserController, except: [:new, :edit]
    put "/users", UserController, :change_password
  end

  def swagger_info do
    %{
      schemes: ["http"],
      info: %{
        version: "1.0",
        title: "TDAuth"
      },
      "basePath": "/api",
      "securityDefinitions":
      %{
        bearer:
        %{
          "type": "apiKey",
          "name": "Authorization",
          "in": "header",
        }
      },
      "security": [
        %{
          bearer: []
        }
      ]
    }
  end
end
