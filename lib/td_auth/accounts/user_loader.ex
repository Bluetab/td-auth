defmodule TdAuth.UserLoader do
  @moduledoc """
  GenServer to load users into Redis
  """

  use GenServer

  alias TdAuth.Accounts
  alias TdPerms.UserCache

  require Logger

  @cache_users_on_startup Application.get_env(:td_auth, :cache_users_on_startup)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, [name: name])
  end

  def refresh(user_id) do
    GenServer.call(TdAuth.UserLoader, {:refresh, user_id})
  end

  def delete(user_id) do
    GenServer.call(TdAuth.UserLoader, {:delete, user_id})
  end

  @impl true
  def init(state) do
    if @cache_users_on_startup, do: schedule_work(:load_cache, 0)
    {:ok, state}
  end

  @impl true
  def handle_call({:refresh, user_id}, _from, state) do
    load_user(user_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, user_id}, _from, state) do
    UserCache.delete_user(user_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:load_cache, state) do
    load_all_users()

    {:noreply, state}
  end

  defp schedule_work(action, seconds) do
    Process.send_after(self(), action, seconds)
  end

  defp load_user(user_id) do
    user = Accounts.get_user!(user_id)
    load_user_data([user])
  end

  defp load_all_users do
    users = Accounts.list_users()
    load_user_data(users)
  end

  def load_user_data(users) do
    results = users
    |> Enum.map(&(Map.take(&1, [:id, :user_name, :full_name, :email])))
    |> Enum.map(&(UserCache.put_user(&1)))
    |> Enum.map(fn {res, _} -> res end)

    if Enum.any?(results, &(&1 != :ok)) do
      Logger.warn("Cache loading failed")
    else
      Logger.info("Cached #{length(results)} users")
    end
  end
end
