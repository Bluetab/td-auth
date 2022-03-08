defmodule TdAuthWeb.UserPermissionController do
  use TdAuthWeb, :controller

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
end
