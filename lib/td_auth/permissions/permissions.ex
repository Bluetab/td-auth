defmodule TdAuth.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

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
  def list_permissions do
    Repo.all(Permission)
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
  def get_permission!(id), do: Repo.get!(Permission, id)

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
    permission_names = permissions |> Enum.map(& &1.name)
    %{resource_type: resource_type, resource_id: resource_id, permissions: permission_names}
  end
end
