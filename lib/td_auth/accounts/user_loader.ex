defmodule TdAuth.Accounts.UserLoader do
  @moduledoc """
  GenServer to load users into distributed cache.
  """

  use GenServer

  alias TdAuth.Accounts
  alias TdCache.UserCache

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def refresh(user_id) do
    GenServer.call(__MODULE__, {:refresh, user_id})
  end

  def delete(user_id) do
    GenServer.call(__MODULE__, {:delete, user_id})
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
  def handle_call({:refresh, user_id}, _from, state) do
    load_user(user_id)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete, user_id}, _from, state) do
    reply = UserCache.delete(user_id)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_info(:load_cache, state) do
    load_all_users()

    {:noreply, state}
  end

  defp schedule_work(action, millis) do
    Process.send_after(self(), action, millis)
  end

  defp load_user(user_id) do
    user = Accounts.get_user!(user_id)
    load_user_data([user])
  end

  def load_all_users do
    users = Accounts.list_users()
    load_user_data(users)
  end

  def load_user_data(users) do
    results =
      users
      |> Enum.map(&Map.take(&1, [:id, :external_id, :user_name, :full_name, :email]))
      |> Enum.map(&UserCache.put/1)
      |> Enum.map(fn {res, _} -> res end)

    if Enum.any?(results, &(&1 != :ok)) do
      Logger.warn("Cache loading failed")
    else
      Logger.info("Cached #{length(results)} users")
    end
  end
end
