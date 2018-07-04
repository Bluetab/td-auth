defmodule TdAuthWeb.Router do
  use TdAuthWeb, :router

  @endpoint_url "#{Application.get_env(:td_auth, TdAuthWeb.Endpoint)[:url][:host]}:#{Application.get_env(:td_auth, TdAuthWeb.Endpoint)[:url][:port]}"

  pipeline :api_unsecured do
    plug TdAuth.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secured do
    plug TdAuth.Auth.Pipeline.Secure
    plug :accepts, ["json"]
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_auth, swagger_file: "swagger.json"
  end

  scope "/api", TdAuthWeb do
    pipe_through :api_unsecured
    get "/ping", PingController, :ping
    post "/sessions", SessionController, :create
  end

  scope "/api", TdAuthWeb do
    pipe_through [:api_secured]

    post "/sessions/refresh", SessionController, :refresh

    get "/sessions", SessionController, :ping
    delete "/sessions", SessionController, :destroy
    post "/groups/users", UserController, :get_groups_users
    resources "/users", UserController, except: [:new, :edit] do
      patch "/change_password", UserController, :change_password
      get "/groups", GroupController, :user_groups
      post "/groups", GroupController, :add_groups_to_user
      delete "/groups/:id", GroupController, :delete_user_groups
    end
    post "/users/search", UserController, :search
    resources "/groups", GroupController, except: [:new, :edit]
    post "/groups/search", GroupController, :search

    resources "/acl_entries", AclEntryController, except: [:new, :edit]
    post "/acl_entries/create_or_update", AclEntryController, :create_or_update

    resources "/permissions", PermissionController, except: [:new, :edit, :update, :delete, :create]
    resources "/roles", RoleController, except: [:new, :edit] do
      get     "/permissions", PermissionController, :get_role_permissions
      post    "/permissions", PermissionController, :add_permissions_to_role
    end

  end

  def swagger_info do
    %{
      schemes: ["http"],
      info: %{
        version: "1.0",
        title: "TDAuth"
      },
      "host": @endpoint_url,
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
