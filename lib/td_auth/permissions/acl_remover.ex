defmodule TdAuth.Permissions.AclRemover do
  @moduledoc """
  GenServer to periodically remove ACL entries from deleted domains
  """

  use GenServer

  alias TdAuth.Permissions.AclEntries
  alias TdCache.TaxonomyCache

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_init_arg) do
    {:ok, :no_state}
  end

  def dispatch do
    GenServer.cast(__MODULE__, :delete)
  end

  @impl GenServer
  def handle_cast(:delete, state) do
    domain_ids = TaxonomyCache.get_deleted_domain_ids()

    count =
      case domain_ids do
        [_ | _] ->
          {n, _members} =
            AclEntries.delete_acl_entries(resource_type: "domain", resource_id: {:in, domain_ids})

          n

        _ ->
          0
      end

    Logger.info("Deleted #{count} domains")

    {:noreply, state}
  end
end
