defmodule TdAuth.Application do
  @moduledoc """
  The Truedat Auth application module.
  """

  use Application

  alias TdAuthWeb.Endpoint

  @impl true
  def start(_type, _args) do
    env = Application.get_env(:td_auth, :env)

    # Define workers and child supervisors to be supervised
    children =
      [
        TdAuth.Repo,
        TdAuthWeb.Endpoint
      ] ++ workers(env)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TdAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  defp workers(:test), do: []

  defp workers(_env) do
    [
      TdAuth.Permissions.Seeds,
      TdAuth.Accounts.UserLoader,
      TdAuth.Accounts.GroupLoader,
      TdAuth.Permissions.RoleLoader,
      TdAuth.Scheduler
    ] ++ oidc_workers() ++ saml_workers() ++ ldap_workers()
  end

  defp ldap_workers do
    validations_file =
      :td_auth
      |> Application.get_env(:ldap)
      |> Keyword.get(:validations_file)

    [{TdAuth.Ldap.LdapWorker, validations_file}]
  end

  defp saml_workers do
    config = Application.get_env(:td_auth, :saml)

    if empty_config?(config, :sp_id),
      do: [],
      else: [{TdAuth.Saml.SamlWorker, config}]
  end

  defp oidc_workers do
    config = Application.get_env(:td_auth, :openid_connect_providers)

    if empty_config?(config, :client_id),
      do: [],
      else: [{OpenIDConnect.Worker, config}]
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
