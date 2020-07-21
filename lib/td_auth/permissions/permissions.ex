defmodule TdAuth.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias TdAuth.Accounts
  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Permissions.Roles
  alias TdAuth.Repo
  alias TdCache.TaxonomyCache

  @default_preloads :permission_group

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions(opts \\ [preload: @default_preloads]) do
    filter_clauses = Keyword.put_new(opts, :preload, @default_preloads)

    Permission
    |> do_where(filter_clauses)
    |> Repo.all()
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
  def get_permission!(id, opts \\ [preload: @default_preloads]) do
    with preloads <- Keyword.get(opts, :preload, []) do
      Permission
      |> Repo.get!(id)
      |> Repo.preload(preloads)
    end
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

  def update_permission(%Permission{} = permission, params) do
    permission
    |> Permission.changeset(params)
    |> Repo.update()
  end

  def retrieve_acl_with_permissions(user_id) do
    alias TdAuth.Accounts

    user_id
    |> Accounts.get_user_acls()
    |> Repo.preload(role: [permissions: :permission_group])
    |> Enum.map(&acl_entry_to_permissions/1)
  end

  def cache_session_permissions([], _jti, _exp), do: []

  def cache_session_permissions(acl_entries, jti, exp) do
    do_cache_session_permissions(jti, exp, acl_entries)
  end

  def do_cache_session_permissions(_jti, _exp, []), do: []

  def do_cache_session_permissions(jti, exp, acl_entries) when is_list(acl_entries) do
    TdCache.Permissions.cache_session_permissions!(jti, exp, acl_entries)
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

  @doc """
  Returns the list of permission_groups.

  ## Examples

      iex> list_permission_groups()
      [%PermissionGroup{}, ...]

  """
  def list_permission_groups do
    Repo.all(PermissionGroup)
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
  def get_permission_group!(id) do
    Repo.get!(PermissionGroup, id)
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
    attrs
    |> PermissionGroup.changeset()
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
  def update_permission_group(%PermissionGroup{} = permission_group, params) do
    permission_group
    |> PermissionGroup.changeset(params)
    |> Repo.update()
  end

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

  defp do_where(queryable, filter_clauses) do
    Enum.reduce(filter_clauses, queryable, fn
      {:id, {:in, ids}}, q -> where(q, [p], p.id in ^ids)
      {:preload, preloads}, q -> preload(q, ^preloads)
      _, q -> q
    end)
  end

  def get_permissions_domains(%{is_admin: true}, perms) do
    all_domains =
      TaxonomyCache.get_domain_ids()
      |> Enum.map(&TaxonomyCache.get_domain/1)
      |> Enum.map(&Map.take(&1, [:id, :name]))

    Enum.map(perms, &%{name: &1, domains: all_domains})
  end

  def get_permissions_domains(%{id: user}, perms) do
    acls = Accounts.get_user_acls(user, [:group, [role: :permissions], :user])

    default_acls =
      case Roles.get_by(is_default: true, preload: [permissions: :permission_group]) do
        %{permissions: permissions} ->
          names = Enum.map(permissions, &%{name: &1.name})
          domain_ids = TaxonomyCache.get_domain_ids()
          domain_ids
          |> Enum.map(
            &%{
              role: %{permissions: names},
              group: nil,
              resource_type: "domain",
              resource_id: &1
            }
          )

        _nil ->
          []
      end

    all_acls = acls ++ default_acls

    Enum.map(perms, fn perm_name ->
      domains =
        all_acls
        |> Enum.filter(&(&1.resource_type == "domain"))
        |> Enum.filter(fn acl_entry ->
          Enum.any?(acl_entry.role.permissions, &(&1.name == perm_name))
        end)
        |> Enum.map(&Map.get(&1, :resource_id))
        |> Enum.uniq()
        |> Enum.map(fn domain_id -> %{id: domain_id, name: TaxonomyCache.get_name(domain_id)} end)

      %{name: perm_name, domains: domains}
    end)
  end
end
