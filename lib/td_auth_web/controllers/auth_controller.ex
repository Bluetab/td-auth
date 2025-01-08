defmodule TdAuthWeb.AuthController do
  use TdAuthWeb, :controller

  alias TdAuth.Saml.SamlWorker
  alias TdAuthWeb.AuthProvider.Auth0
  alias TdAuthWeb.AuthProvider.OIDC

  action_fallback(TdAuthWeb.FallbackController)

  def index(conn, params) do
    oidc_config =
      :td_auth
      |> Application.get_env(:openid_connect_providers)
      |> Enum.into(%{})
      |> Map.get(:oidc, [])

    auth0_config = Application.get_env(:td_auth, :auth0)
    url = Map.get(params, "url")

    auth_methods =
      %{}
      |> add_oidc_auth(oidc_config, url)
      |> add_auth0_auth(auth0_config, url)
      |> add_saml_auth()

    render(conn, "index.json", auth_methods: auth_methods)
  end

  defp add_saml_auth(auth_methods) do
    case SamlWorker.auth_url() do
      nil -> auth_methods
      url -> Map.put(auth_methods, :saml_idp, url)
    end
  end

  defp add_oidc_auth(auth_methods, config, pre_login_url) do
    case empty_config?(config, :client_id) do
      true ->
        auth_methods

      _ ->
        oidc_url = OIDC.authentication_url(pre_login_url)
        Map.put(auth_methods, :oidc, oidc_url)
    end
  end

  defp add_auth0_auth(auth_methods, config, pre_login_url) do
    case empty_config?(config, :domain) do
      true ->
        auth_methods

      _ ->
        auth0 = Auth0.auth0_config(config, pre_login_url)
        Map.put(auth_methods, :auth0, auth0)
    end
  end

  defp empty_config?(nil, _), do: true

  defp empty_config?(config, check_field) do
    config
    |> Enum.into(%{})
    |> Map.get(check_field)
    |> nil_or_empty?()
  end

  defp nil_or_empty?(nil), do: true
  defp nil_or_empty?(""), do: true
  defp nil_or_empty?(_), do: false
end
