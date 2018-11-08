defmodule TdAuthWeb.AuthController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuthWeb.AuthProvider.OIDC
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback(TdAuthWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.auth_swagger_definitions()
  end

  swagger_path :index do
    description("List Authentication Methods")
    produces("application/json")
    response(200, "OK", Schema.ref(:AuthenticationMethodsResponse))
  end

  def index(conn, _params) do
    url = OIDC.authentication_url()
    render(conn, "index.json", urls: [url])
  end
end
