defmodule TdAuthWeb.UserPermissionController do
  use TdAuthWeb, :controller

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions
  alias TdAuthWeb.SwaggerDefinitions

  require Logger

  action_fallback TdAuthWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.user_swagger_definitions()
  end

  swagger_path :show do
    description("Show User")
    produces("application/json")

    parameters do
      user_id(:path, :string, "User ID: me", required: true)

      permissions(
        :query,
        :string,
        "List of permissions separated by comma",
        required: false
      )
    end

    response(200, "OK", Schema.ref(:PermissionDomainsResponseData))
    response(400, "Client Error")
  end

  def show(conn, %{"user_id" => "me", "permissions" => perms}) do
    permissions = String.split(perms, ",")
    %{user_id: user_id} = conn.assigns[:current_resource]

    case Accounts.get_user!(user_id) do
      %User{} = user ->
        permission_domains = Permissions.get_permissions_domains(user, permissions)
        render(conn, "show.json", permission_domains: permission_domains)
    end
  end
end
