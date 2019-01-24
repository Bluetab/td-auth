defmodule TdAuthWeb.AuthController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias TdAuth.Saml.SamlWorker
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
    oidc_config =
      :td_auth
      |> Application.get_env(:openid_connect_providers)
      |> Enum.into(%{})
      |> Map.get(:oidc, [])

    auth0_config = Application.get_env(:td_auth, :auth)

    auth_methods =
      %{}
      |> add_oidc_auth(oidc_config)
      |> add_auth0_auth(auth0_config)
      |> add_saml_auth()

    render(conn, "index.json", auth_methods: auth_methods)
  end

  defp add_saml_auth(auth_methods) do
    case SamlWorker.auth_url() do
      nil -> auth_methods
      url -> Map.put(auth_methods, :saml_idp, url)
    end
  end

  defp add_oidc_auth(auth_methods, config) do
    case empty_config?(config, :client_id) do
      true ->
        auth_methods

      _ ->
        oidc_url = OIDC.authentication_url()
        Map.put(auth_methods, :oidc, oidc_url)
    end
  end

  defp add_auth0_auth(auth_methods, auth0_config) do
    case empty_config?(auth0_config, :domain) do
      true ->
        auth_methods

      _ ->
        auth0 = %{
          domain: auth0_config[:domain],
          clientID: auth0_config[:client_id],
          redirectUri: auth0_config[:redirect_uri],
          audience: Enum.join([auth0_config[:audience], auth0_config[:userinfo]], ""),
          responseType: auth0_config[:response_type],
          scope: auth0_config[:scope]
        }
        Map.put(auth_methods, :auth0, auth0)
    end
  end

  defp empty_config?(nil, _), do: true

  defp empty_config?(config, check_field) do
    config
    |> Enum.into(%{})
    |> Map.get(check_field)
    |> (fn v -> v == "" or is_nil(v) end).()
  end
end
