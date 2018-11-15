defmodule TdAuth.AclRemover do
  @moduledoc """
  GenServer used to remove from acl_entries the deleted domains
  """
  use GenServer
  alias TdAuth.Permissions.AclEntry
  alias TdPerms.TaxonomyCache
  require Logger

  @acl_removement_frequency Application.get_env(
                                  :td_auth,
                                  :acl_removement_frequency
                                )

  @acl_removement Application.get_env(:td_auth, :acl_removement)

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    # Schedule work to be performed at some point
    if @acl_removement, do: schedule_work()
    {:ok, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @acl_removement_frequency)
  end

  def handle_info(:work, state) do
    domain_ids =
      TaxonomyCache.get_domain_name_to_id_map()
      |> Map.values()

    AclEntry.delete_acl_entries(%{resource_id: domain_ids, resource_type: "domain"}, %{
      resource_id: :negative
    })

    schedule_work()
    {:noreply, state}
  end
end
