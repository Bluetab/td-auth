defmodule TdAuth.Application do
  @moduledoc false
  use Application
  alias TdAuth.Metrics.PrometheusExporter
  alias TdAuthWeb.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    acl_remover_worker = %{
      id: TdAuth.AclRemover,
      start: {TdAuth.AclRemover, :start_link, []}
    }

    # Setup metrics exporter
    PrometheusExporter.setup()

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        supervisor(TdAuth.Repo, []),
        # Start the endpoint when the application starts
        supervisor(TdAuthWeb.Endpoint, []),
        # Start your own worker by calling: TdAuth.Worker.start_link(arg1, arg2, arg3)
        # worker(TdAuth.Worker, [arg1, arg2, arg3]),
        worker(TdAuth.UserLoader, [TdAuth.UserLoader]),
        worker(TdAuth.AclLoader, [TdAuth.AclLoader]),
        %{
          id: TdAuth.CustomSupervisor,
          start:
            {TdAuth.CustomSupervisor, :start_link,
             [%{children: [acl_remover_worker], strategy: :one_for_one}]},
          type: :supervisor
        }
      ] ++ oidc_workers()

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

  defp oidc_workers do
    import Supervisor.Spec

    config = Application.get_env(:td_auth, :openid_connect_providers)

    if empty_config?(config), do: [], else: [worker(OpenIDConnect.Worker, [config])]
  end

  defp empty_config?(config) do
    config
    |> Keyword.values()
    |> Enum.map(& &1[:client_id])
    |> Enum.filter(&(&1 !== "" and not is_nil(&1)))
    |> Enum.empty?()
  end
end
