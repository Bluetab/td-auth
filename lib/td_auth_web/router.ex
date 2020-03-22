defmodule TdAuthWeb.Router do
  use TdAuthWeb, :router

  pipeline :api_unsecured do
    plug(TdAuth.Auth.Pipeline.Unsecure)
    plug(:accepts, ["json"])
  end

  pipeline :api_secured do
    plug(TdAuth.Auth.Pipeline.Secure)
    plug(:accepts, ["json"])
  end

  scope "/api/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_auth, swagger_file: "swagger.json")
  end

  scope "/api", TdAuthWeb do
    pipe_through(:api_unsecured)
    get("/auth", AuthController, :index)
    get("/ping", PingController, :ping)
    post("/sessions", SessionController, :create)
    post("/init", UserController, :init)
  end

  scope "/", TdAuthWeb do
    pipe_through(:api_unsecured)
    post("/callback", SessionController, :create)
  end

  scope "/api", TdAuthWeb do
    pipe_through([:api_secured])

    post("/sessions/refresh", SessionController, :refresh)

    get("/sessions", SessionController, :ping)
    delete("/sessions", SessionController, :destroy)

    post("/update_password", UserController, :update_password)

    resources "/users", UserController, except: [:new, :edit] do
      patch("/change_password", UserController, :change_password)
    end

    resources("/groups", GroupController, except: [:new, :edit])

    resources("/acl_entries", AclEntryController, except: [:new, :edit])
    post("/acl_entries/create_or_update", AclEntryController, :create_or_update)

    resources("/permissions", PermissionController,
      except: [:new, :edit, :update, :delete, :create]
    )

    resources "/permission_groups", PermissionGroupController, except: [:new, :edit]

    resources "/roles", RoleController, except: [:new, :edit] do
      resources("/permissions", RolePermissionController, singleton: true, only: [:show, :update], name: "permission")
    end

    resources("/:resource_type", ResourceController, only: [:show]) do
      resources("/acl_entries", ResourceAclController, singleton: true, only: [:show, :update], name: "acl")
    end
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
