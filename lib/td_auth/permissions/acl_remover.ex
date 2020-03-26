defmodule TdAuth.Permissions.AclRemover do
  @moduledoc """
  GenServer to periodically remove ACL entries from deleted domains
  """

  use GenServer

  alias TdAuth.Permissions.AclEntries
  alias TdCache.TaxonomyCache

  require Logger

  @hourly 60 * 60 * 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(state) do
    if Application.get_env(:td_auth, :env) == :prod do
      schedule_work()
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    domain_ids =
      TaxonomyCache.get_domain_name_to_id_map()
      |> Map.values()

    AclEntries.delete_acl_entries(resource_type: "domain", resource_id: {:not_in, domain_ids})

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work(millis \\ @hourly) do
    Process.send_after(self(), :work, millis)
  end
end
