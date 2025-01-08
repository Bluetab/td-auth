defmodule TdAuthWeb.Router do
  use TdAuthWeb, :router

  pipeline :api_unsecured do
    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(TdAuth.Auth.Pipeline.Secure)
    plug(:accepts, ["json"])
  end

  scope "/api", TdAuthWeb do
    pipe_through(:api_unsecured)
    get("/auth", AuthController, :index)
    get("/ping", PingController, :ping)
    post("/sessions", SessionController, :create)
    post("/init", UserController, :init)
    get("/init/can", UserController, :can_init)
  end

  scope "/", TdAuthWeb do
    pipe_through(:api_unsecured)
    post("/callback", SessionController, :create)
  end

  scope "/api", TdAuthWeb do
    pipe_through(:api_auth)

    get("/sessions", SessionController, :ping)
    post("/sessions/refresh", SessionController, :refresh)
    delete("/sessions", SessionController, :destroy)

    resources("/users/search", UserSearchController, only: [:create], singleton: true)

    get("/users/agents", UserController, :agents)
    resources("/users", UserController, except: [:new, :edit])

    resources("/password", PasswordController, only: [:update], singleton: true)
    resources("/groups/search", GroupSearchController, only: [:create], singleton: true)

    resources("/groups", GroupController, except: [:new, :edit])

    resources("/acl_entries", AclEntryController, except: [:new, :edit])

    resources("/permissions", PermissionController, except: [:new, :edit, :update])

    resources("/permission_groups", PermissionGroupController, except: [:edit])

    resources "/roles", RoleController, except: [:edit] do
      resources("/permissions", RolePermissionController,
        singleton: true,
        name: "permission"
      )
    end

    resources("/acl_entries/:resource_type/:resource_id", ResourceAclController,
      singleton: true,
      only: [:show, :create],
      name: "acl"
    )
  end

  def swagger_info do
    %{
      schemes: ["http", "https"],
      info: %{
        version: Application.spec(:td_auth, :vsn),
        title: "Truedat Authorization Service"
      },
      securityDefinitions: %{
        bearer: %{
          type: "apiKey",
          name: "Authorization",
          in: "header"
        }
      },
      security: [
        %{
          bearer: []
        }
      ]
    }
  end
end
