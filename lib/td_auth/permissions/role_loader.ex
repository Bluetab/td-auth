defmodule TdAuth.Permissions.RoleLoader do
  @moduledoc """
  Loads cache entries for roles and permissions.
  """

  use GenServer

  alias TdAuth.Permissions
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry
  alias TdCache.UserCache

  # Public API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def load_roles(opts) when is_list(opts) do
    GenServer.cast(__MODULE__, {:load_roles, opts})
  end

  def load_roles(%AclEntry{} = acl_entry, opts \\ []) do
    GenServer.call(__MODULE__, {:load_roles, acl_entry, opts})
  end

  def delete_roles(%AclEntry{} = acl_entry) do
    GenServer.call(__MODULE__, {:delete_roles, acl_entry})
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:load_roles, opts}, state) do
    {:ok, _} = put_permission_roles()
    {:ok, _} = put_default_permissions()
    put_roles(opts)
    {:noreply, state}
  end

  @impl true
  def handle_call({:load_roles, acl_entry, opts}, _from, state) do
    {:ok, _} = put_permission_roles()
    {:ok, _} = put_default_permissions()

    reply = put_roles(acl_entry, opts)

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:delete_roles, acl_entry}, _from, state) do
    {:ok, _} = put_permission_roles()
    {:ok, _} = put_default_permissions()

    reply = do_deleted_roles(acl_entry)

    {:reply, reply, state}
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

  def put_roles(opts) do
    AclEntries.list_acl_entries(%{
      resource_types: ["domain", "structure"],
      preload: [:role, group: :users]
    })
    |> Enum.flat_map(&to_entries/1)
    |> do_put_roles(opts)
  end

  def put_roles(
        %AclEntry{user_id: user_id, resource_type: resource_type, resource_id: resource_id},
        opts
      )
      when not is_nil(user_id) do
    AclEntries.list_acl_entries(%{
      resource_types: [resource_type],
      user_id: user_id,
      resource_id: resource_id,
      preload: [:role, group: :users]
    })
    |> Enum.flat_map(&to_entries/1)
    |> do_put_roles(opts)
  end

  def put_roles(
        %AclEntry{group_id: group_id, resource_type: resource_type, resource_id: resource_id},
        opts
      )
      when not is_nil(group_id) do
    AclEntries.list_acl_entries(%{
      resource_types: [resource_type],
      group_id: group_id,
      resource_id: resource_id,
      preload: [:role, group: :users]
    })
    |> Enum.flat_map(&to_entries/1)
    |> do_put_roles(opts)
  end

  def do_put_roles(entries, opts) do
    entries
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, entries} ->
      entries
      |> Enum.group_by(& &1.resource_type)
      |> Enum.map(fn {resource_type, group} ->
        {resource_type, Enum.group_by(group, & &1.role, & &1.resource_id)}
      end)
      |> Enum.map(fn {resource_type, resource_ids_by_role} ->
        {:ok, _} = UserCache.put_roles(user_id, resource_ids_by_role, resource_type, opts)
      end)
    end)

    entries
  end

  def do_deleted_roles(acl_entry) do
    acl_entry
    |> to_entries()
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, entries} ->
      entries
      |> Enum.group_by(& &1.resource_type)
      |> Enum.map(fn {resource_type, group} ->
        {resource_type, Enum.group_by(group, & &1.role, & &1.resource_id)}
      end)
      |> Enum.map(fn {resource_type, resource_ids_by_role} ->
        {:ok, _} = UserCache.delete_roles(user_id, resource_ids_by_role, resource_type)
      end)
    end)
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
