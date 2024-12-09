defmodule TdAuth.Permissions.RoleLoader do
  @moduledoc """
  Loads cache entries for roles and permissions.
  """

  use GenServer

  alias TdAuth.Accounts
  alias TdAuth.Permissions
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry
  alias TdCache.UserCache

  # Public API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def load_roles do
    GenServer.cast(__MODULE__, {:refresh_all_user_roles})
  end

  def refresh_acl_roles(%AclEntry{} = acl_entry) do
    GenServer.call(__MODULE__, {:refresh_resource_roles, acl_entry})
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:refresh_all_user_roles}, state) do
    refresh()
    {:noreply, state}
  end

  @impl true
  def handle_call({:refresh_resource_roles, acl_entry}, _from, state) do
    {:ok, _} = put_permission_roles()
    {:ok, _} = put_default_permissions()

    reply = refresh_resource_roles(acl_entry)

    {:reply, reply, state}
  end

  def put_default_permissions do
    perms = Permissions.default_permissions()
    TdCache.Permissions.put_default_permissions(perms)
  end

  def put_permission_roles do
    Permissions.list_permissions(preload: :roles)
    |> Enum.reject(&Enum.empty?(&1.roles))
    |> Map.new(fn %{name: name, roles: roles} -> {name, Enum.map(roles, & &1.name)} end)
    |> cache_permissions_roles()
  end

  def refresh do
    {:ok, _} = put_permission_roles()
    {:ok, _} = put_default_permissions()
    refresh_all_user_roles()
  end

  def refresh_all_user_roles do
    %{preload: [:role, group: :users]}
    |> AclEntries.list_acl_entries()
    |> Enum.flat_map(&to_entries/1)
    |> Enum.group_by(& &1.user_id)
    |> Enum.into(%{}, fn {user_id, entries} ->
      {user_id,
       entries
       |> Enum.group_by(& &1.resource_type)
       |> Enum.into(%{}, fn {resource_type, group} ->
         {resource_type, Enum.group_by(group, & &1.role, & &1.resource_id)}
       end)}
    end)
    |> UserCache.refresh_all_roles()
  end

  def refresh_resource_roles(%AclEntry{user_id: user_id, resource_type: resource_type})
      when not is_nil(user_id),
      do: refresh_resource_roles(user_id, resource_type)

  def refresh_resource_roles(%AclEntry{group_id: group_id, resource_type: resource_type})
      when not is_nil(group_id) do
    group_id
    |> Accounts.get_group(preload: :users)
    |> Map.get(:users)
    |> Enum.map(&refresh_resource_roles(&1.id, resource_type))
  end

  def refresh_resource_roles(user_id, resource_type) do
    entries =
      AclEntries.list_acl_entries(%{
        resource_types: [resource_type],
        all_for_user: user_id,
        preload: [:role]
      })
      |> Enum.map(&to_entry(&1, user_id))
      |> Enum.group_by(& &1.role, & &1.resource_id)

    UserCache.refresh_resource_roles(user_id, resource_type, entries)
  end

  defp cache_permissions_roles(permissions) when permissions == %{}, do: {:ok, nil}

  defp cache_permissions_roles(permissions) do
    TdCache.Permissions.put_permission_roles(permissions)
  end

  defp to_entries(%{group: %{users: users}} = acl_entry) do
    user_ids = Enum.map(users, & &1.id)
    Enum.map(user_ids, &to_entry(acl_entry, &1))
  end

  defp to_entries(%{user_id: user_id} = acl_entry) when is_integer(user_id) do
    [to_entry(acl_entry, user_id)]
  end

  defp to_entry(
         %{
           role: %{name: role},
           resource_type: resource_type,
           resource_id: resource_id,
           updated_at: ts
         },
         user_id
       ) do
    %{
      user_id: user_id,
      role: role,
      resource_type: resource_type,
      resource_id: resource_id,
      updated_at: ts
    }
  end
end
