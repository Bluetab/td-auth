defmodule TdAuth.AclLoader do
  @moduledoc """
  GenServer to load acl into Redis
  """

  use GenServer

  alias TdAuth.Permissions.AclEntry
  alias TdPerms.AclCache

  require Logger

  @cache_acl_on_startup Application.get_env(:td_auth, :cache_acl_on_startup)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, [name: name])
  end

  def refresh(resource_type, resource_id) do
    GenServer.call(TdAuth.AclLoader, {:refresh, resource_type, resource_id})
  end

  def delete(resource_type, resource_id) do
    GenServer.call(TdAuth.AclLoader, {:delete, resource_type, resource_id})
  end

  @impl true
  def init(state) do
    if @cache_acl_on_startup, do: schedule_work(:load_cache, 0)
    {:ok, state}
  end

  @impl true
  def handle_call({:refresh, resource_type, resource_id}, _from, state) do
    set_role_and_users(resource_type, resource_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, resource_type, resource_id}, _from, state) do
    roles = AclCache.get_acl_roles(resource_type, resource_id)
    Enum.each(roles, fn role ->
      {:ok, _} = AclCache.delete_acl_role_users(resource_type, resource_id, role)
    end)
    {:ok, _} = AclCache.delete_acl_roles(resource_type, resource_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:load_cache, state) do
    AclEntry.list_acl_resources() |> set_roles_and_users
    {:noreply, state}
  end

  defp schedule_work(action, seconds) do
    Process.send_after(self(), action, seconds)
  end

  defp set_roles_and_users(key_values) do
    Enum.each(key_values, fn {resource_type, resource_id} ->
      set_role_and_users(resource_type, resource_id)
    end)
  end
  defp set_role_and_users(resource_type, resource_id) do
    roles_and_users = AclEntry.list_user_roles(resource_type, resource_id)
    roles = Enum.map(roles_and_users, fn {role, users} ->
      users = Enum.map(users, & &1.id)
      {:ok, _} = AclCache.set_acl_role_users(resource_type, resource_id, role, users)
      role
    end)
    {:ok, _} = AclCache.set_acl_roles(resource_type, resource_id, roles)
  end
end