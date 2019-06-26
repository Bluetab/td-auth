defmodule TdAuth.AclRemover do
  @moduledoc """
  GenServer used to remove from acl_entries the deleted domains
  """

  use GenServer

  alias TdAuth.Permissions.AclEntry
  alias TdCache.TaxonomyCache

  require Logger

  @hourly 60 * 60 * 1000

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    # Schedule work to be performed at some point
    if Application.get_env(:td_auth, :env) == :prod do
      schedule_work()
    end

    {:ok, state}
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

  defp schedule_work(millis \\ @hourly) do
    Process.send_after(self(), :work, millis)
  end
end
