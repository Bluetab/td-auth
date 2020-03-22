defmodule TdAuth.Application do
  @moduledoc """
  The Truedat Auth application module.
  """

  use Application

  alias TdAuth.Metrics.PrometheusExporter
  alias TdAuthWeb.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    env = Application.get_env(:td_auth, :env)

    # Setup metrics exporter
    PrometheusExporter.setup()

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        TdAuth.Repo,
        # Start the endpoint when the application starts
        TdAuthWeb.Endpoint,
        # Start your own worker by calling: TdAuth.Worker.start_link(arg1, arg2, arg3)
        # worker(TdAuth.Worker, [arg1, arg2, arg3]),
        #{Hypermedia, router: TdAuthWeb.Router, subject: :current_resource}
      ] ++ workers(env)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TdAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  defp workers(:test), do: []

  defp workers(_env) do
    [
      TdAuth.Permissions.Seeds,
      TdAuth.Accounts.UserLoader,
      TdAuth.Permissions.AclLoader,
      TdAuth.Permissions.AclRemover,
    ] ++ oidc_workers() ++ saml_workers() ++ ldap_workers()
  end

  defp ldap_workers do
    import Supervisor.Spec

    validations_file =
      :td_auth
      |> Application.get_env(:ldap)
      |> Keyword.get(:validations_file, "")

    [worker(TdAuth.Ldap.LdapWorker, [validations_file])]
  end

  defp saml_workers do
    import Supervisor.Spec
    config = Application.get_env(:td_auth, :saml)

    if empty_config?(config, :sp_id),
      do: [],
      else: [worker(TdAuth.Saml.SamlWorker, [config])]
  end

  defp oidc_workers do
    import Supervisor.Spec

    config = Application.get_env(:td_auth, :openid_connect_providers)

    if empty_config?(config, :client_id),
      do: [],
      else: [worker(OpenIDConnect.Worker, [config])]
  end

  defp empty_config?(nil, _), do: true

  defp empty_config?(config, :client_id) do
    config
    |> Keyword.values()
    |> Enum.map(& &1[:client_id])
    |> Enum.filter(&(&1 !== "" and not is_nil(&1)))
    |> Enum.empty?()
  end

  defp empty_config?(config, keyword) do
    case Keyword.get(config, keyword) do
      nil -> true
      "" -> true
      _ -> false
    end
  end
end
