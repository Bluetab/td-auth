defmodule TdAuth.Accounts.GroupLoader do
  @moduledoc """
  GenServer to load groups into distributed cache.
  """

  use GenServer

  alias TdAuth.Accounts
  alias TdCache.UserCache

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def refresh(group_id) do
    GenServer.call(__MODULE__, {:refresh, group_id})
  end

  def delete(group_id) do
    GenServer.call(__MODULE__, {:delete, group_id})
  end

  @impl GenServer
  def init(state) do
    unless Application.get_env(:td_auth, :env) == :test do
      schedule_work(:load_cache, 0)
    end

    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:refresh, group_id}, _from, state) do
    load_group(group_id)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete, group_id}, _from, state) do
    reply = UserCache.delete(group_id)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_info(:load_cache, state) do
    load_all_groups()

    {:noreply, state}
  end

  defp schedule_work(action, millis) do
    Process.send_after(self(), action, millis)
  end

  defp load_group(group_id) do
    group = Accounts.get_group!(group_id)
    load_group_data([group])
  end

  def load_all_groups do
    groups = Accounts.list_groups()
    load_group_data(groups)
  end

  def load_group_data(groups) do
    results =
      groups
      |> Enum.map(&Map.take(&1, [:id, :name, :description]))
      |> Enum.map(&UserCache.put_group/1)
      |> Enum.map(fn {res, _} -> res end)

    if Enum.any?(results, &(&1 != :ok)) do
      Logger.warn("Cache loading failed")
    else
      Logger.info("Cached #{length(results)} groups")
    end
  end
end
