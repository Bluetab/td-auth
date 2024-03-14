defmodule TdAuth.Permissions.RoleLoader do
  @moduledoc """
  Loads cache entries for roles and permissions.
  """

  use GenServer

  alias TdAuth.Permissions
  alias TdAuth.Permissions.AclEntries
  alias TdCache.UserCache

  # Public API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def load_roles do
    GenServer.cast(__MODULE__, :load_roles)
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    {:ok, _acls_ts = nil}
  end

  @impl true
  def handle_cast(:load_roles, acls_ts) do
    {:ok, _} = put_permission_roles()
    {:ok, _} = put_default_permissions()
    acls_ts = put_roles(acls_ts)

    {:noreply, acls_ts}
  end

  # Private functions (should only be used by this module or tests)

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

  def put_roles(last_updated_at) do
    entries =
      AclEntries.list_acl_entries(%{
        updated_since: last_updated_at,
        resource_types: ["domain", "structure"],
        preload: [:role, group: :users]
      })
      |> Enum.flat_map(&to_entries/1)

    entries
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, entries} ->
      entries
      |> Enum.group_by(& &1.resource_type)
      |> Enum.map(fn {resource_type, group} ->
        {resource_type, Enum.group_by(group, & &1.role, & &1.resource_id)}
      end)
      |> Enum.map(fn {resource_type, resource_ids_by_role} ->
        {:ok, _} = UserCache.put_roles(user_id, resource_ids_by_role, resource_type)
      end)
    end)

    entries
    |> Enum.map(& &1.updated_at)
    |> Enum.max(DateTime, fn -> last_updated_at end)
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
