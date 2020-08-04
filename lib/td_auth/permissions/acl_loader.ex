defmodule TdAuth.Permissions.AclLoader do
  @moduledoc """
  GenServer to load ACL entries into distributed cache.
  """

  use GenServer

  alias TdAuth.Permissions.AclEntries
  alias TdCache.AclCache

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def refresh(resource_type, resource_id) do
    GenServer.call(__MODULE__, {:refresh, resource_type, resource_id})
  end

  def delete(resource_type, resource_id) do
    GenServer.call(__MODULE__, {:delete, resource_type, resource_id})
  end

  def delete_acl(resource_type, resource_id, role, user_id) do
    GenServer.call(__MODULE__, {:delete_acl, resource_type, resource_id, role, user_id})
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
  def handle_call({:refresh, resource_type, resource_id}, _from, state) do
    acls =
      AclEntries.get_user_ids_by_resource_and_role(
        resource_type: resource_type,
        resource_id: resource_id
      )

    if map_size(acls) == 0 do
      delete_resource(resource_type, resource_id)
    else
      put_cache(acls)
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete, resource_type, resource_id}, _from, state) do
    delete_resource(resource_type, resource_id)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete_acl, resource_type, resource_id, role, user_id}, _from, state) do
    AclCache.delete_acl_role_user(resource_type, resource_id, role, user_id)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:load_cache, state) do
    AclEntries.get_user_ids_by_resource_and_role()
    |> put_cache()

    {:noreply, state}
  end

  defp delete_resource(resource_type, resource_id) do
    roles = AclCache.get_acl_roles(resource_type, resource_id)

    Enum.each(roles, fn role ->
      {:ok, _} = AclCache.delete_acl_role_users(resource_type, resource_id, role)
    end)

    {:ok, _} = AclCache.delete_acl_roles(resource_type, resource_id)
  end

  defp schedule_work(action, seconds) do
    Process.send_after(self(), action, seconds)
  end

  defp put_cache(%{} = user_ids_by_resource_and_role) do
    user_ids_by_resource_and_role
    |> Enum.map(fn {{resource_type, resource_id, role} = key, user_ids} ->
      {:ok, _} = AclCache.set_acl_role_users(resource_type, resource_id, role, user_ids)
      key
    end)
    |> Enum.group_by(
      fn {resource_type, resource_id, _} -> {resource_type, resource_id} end,
      fn {_, _, role} -> role end
    )
    |> Enum.each(fn {{resource_type, resource_id}, roles} ->
      {:ok, _} = AclCache.set_acl_roles(resource_type, resource_id, roles)
    end)
  end
end
