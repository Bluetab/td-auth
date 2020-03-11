defmodule TdAuth.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Permission
  alias TdAuth.Repo
  alias TdCache.Permissions

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions(options \\ []) do
    Permission
    |> Repo.all()
    |> preload_options(options)
  end

  @doc """
  Gets a single permission.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permission!(123)
      %Permission{}

      iex> get_permission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission!(id, options \\ []) do
    Permission
    |> Repo.get!(id)
    |> preload_options(options)
  end

  @doc """
  Gets a single permission by name.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permission_by_name("view_domain")
      {:ok, %Permission{}}

      iex> get_permission_by_name("does_not_exist")
      nil

  """
  def get_permission_by_name(name), do: Repo.get_by(Permission, name: name)

  @doc """
  Creates a permission.

  ## Examples

      iex> create_permission(%{name: "custom_permission"})
      {:ok, %Permission{}}

      iex> create_permission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  def retrieve_acl_with_permissions(user_id, gids) do
    %{user_id: user_id, gids: gids}
    |> AclEntry.list_acl_entries_by_user_with_groups()
    |> Enum.map(&acl_entry_to_permissions/1)
  end

  def cache_session_permissions([], _jti, _exp), do: []

  def cache_session_permissions(acl_entries, jti, exp) do
    cache_session_permissions!(jti, exp, acl_entries)
  end

  def cache_session_permissions(user_id, gids, jti, exp) do
    acl_entries = retrieve_acl_with_permissions(user_id, gids)
    cache_session_permissions!(jti, exp, acl_entries)
  end

  def cache_session_permissions!(_jti, _exp, []), do: []

  def cache_session_permissions!(jti, exp, acl_entries) when is_list(acl_entries) do
    Permissions.cache_session_permissions!(jti, exp, acl_entries)
  end

  defp acl_entry_to_permissions(%{
         resource_type: resource_type,
         resource_id: resource_id,
         role: %{permissions: permissions}
       }) do
    groups = Enum.map(permissions, & &1.permission_group)
    permissions = Enum.map(permissions, & &1.name)

    %{
      resource_type: resource_type,
      resource_id: resource_id,
      permissions: permissions,
      groups: groups
    }
  end

  alias TdAuth.Permissions.PermissionGroup

  @doc """
  Returns the list of permission_groups.

  ## Examples

      iex> list_permission_groups()
      [%PermissionGroup{}, ...]

  """
  def list_permission_groups(options \\ []) do
    PermissionGroup
    |> Repo.all()
    |> preload_options(options)
  end

  @doc """
  Gets a single permission_group.

  Raises `Ecto.NoResultsError` if the Permission group does not exist.

  ## Examples

      iex> get_permission_group!(123)
      %PermissionGroup{}

      iex> get_permission_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission_group!(id, options \\ []) do
    PermissionGroup
    |> Repo.get!(id)
    |> preload_options(options)
  end

  @doc """
  Creates a permission_group.

  ## Examples

      iex> create_permission_group(%{field: value})
      {:ok, %PermissionGroup{}}

      iex> create_permission_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_permission_group(attrs \\ %{}) do
    %PermissionGroup{}
    |> PermissionGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a permission_group.

  ## Examples

      iex> update_permission_group(permission_group, %{field: new_value})
      {:ok, %PermissionGroup{}}

      iex> update_permission_group(permission_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_permission_group(%PermissionGroup{} = permission_group, attrs) do
    permission_group
    |> Repo.preload(:permissions)
    |> PermissionGroup.changeset(attrs)
    |> assoc_with_permissions(attrs)
    |> Repo.update()
  end

  defp assoc_with_permissions(changeset, %{"permissions" => permissions}),
    do: Changeset.put_assoc(changeset, :permissions, permissions)

  defp assoc_with_permissions(changeset, %{permissions: permissions}),
    do: Changeset.put_assoc(changeset, :permissions, permissions)

  defp assoc_with_permissions(changeset, _), do: changeset

  @doc """
  Deletes a PermissionGroup.

  ## Examples

      iex> delete_permission_group(permission_group)
      {:ok, %PermissionGroup{}}

      iex> delete_permission_group(permission_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_permission_group(%PermissionGroup{} = permission_group) do
    permission_group
    |> PermissionGroup.delete_changeset()
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking permission_group changes.

  ## Examples

      iex> change_permission_group(permission_group)
      %Ecto.Changeset{source: %PermissionGroup{}}

  """
  def change_permission_group(%PermissionGroup{} = permission_group) do
    PermissionGroup.changeset(permission_group, %{})
  end

  def preload_options([], _), do: []

  def preload_options(%{} = entity, []), do: entity

  def preload_options(entities, []) when is_list(entities), do: entities

  def preload_options(%{} = entity, options) do
    Repo.preload(entity, options)
  end

  def preload_options(entities, options) when is_list(entities) do
    Repo.preload(entities, options)
  end
end
