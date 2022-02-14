defmodule TdAuth.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias TdAuth.Accounts
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.Roles
  alias TdAuth.Repo
  alias TdCache.TaxonomyCache

  @default_preloads :permission_group

  def list_permissions(opts \\ [preload: @default_preloads]) do
    filter_clauses = Keyword.put_new(opts, :preload, @default_preloads)

    Permission
    |> do_where(filter_clauses)
    |> Repo.all()
  end

  def get_permission!(id, opts \\ [preload: @default_preloads]) do
    with preloads <- Keyword.get(opts, :preload, []) do
      Permission
      |> Repo.get!(id)
      |> Repo.preload(preloads)
    end
  end

  def get_permission_by_name(name), do: Repo.get_by(Permission, name: name)

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

  def cache_session_permissions(permissions, _jti, _exp) when permissions == %{}, do: :ok

  def cache_session_permissions(permissions, jti, exp) do
    TdCache.Permissions.cache_session_permissions!(jti, exp, permissions)
  end

  def list_permission_groups do
    Repo.all(PermissionGroup)
  end

  def get_permission_group!(id) do
    Repo.get!(PermissionGroup, id)
  end

  def create_permission_group(attrs \\ %{}) do
    attrs
    |> PermissionGroup.changeset()
    |> Repo.insert()
  end

  def update_permission_group(%PermissionGroup{} = permission_group, params) do
    permission_group
    |> PermissionGroup.changeset(params)
    |> Repo.update()
  end

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

  def get_permissions_domains(%User{role: :admin}, perms) do
    domains =
      TaxonomyCache.domain_map()
      |> Map.values()
      |> Enum.map(&Map.take(&1, [:id, :name, :external_id]))

    Enum.map(perms, &%{name: &1, domains: domains})
  end

  def get_permissions_domains(%User{id: user_id}, perms) do
    acls = Accounts.get_user_acls(user_id, [:group, [role: :permissions], :user])

    default_acls =
      case Roles.get_by(is_default: true, preload: [permissions: :permission_group]) do
        %{permissions: permissions} ->
          names = Enum.map(permissions, &%{name: &1.name})
          domain_ids = TaxonomyCache.get_domain_ids()

          Enum.map(
            domain_ids,
            &%{role: %{permissions: names}, group: nil, resource_type: "domain", resource_id: &1}
          )

        _nil ->
          []
      end

    all_acls = acls ++ default_acls

    Enum.map(perms, fn perm_name ->
      domains =
        all_acls
        |> Enum.filter(&has_domain_permission?(&1, perm_name))
        |> Enum.map(&Map.get(&1, :resource_id))
        |> Enum.uniq()
        |> Enum.map(&TaxonomyCache.get_domain/1)
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.take(&1, [:id, :name, :external_id]))

      %{name: perm_name, domains: domains}
    end)
  end

  defp has_domain_permission?(%{resource_type: "domain", role: %{permissions: permissions}}, name) do
    Enum.any?(permissions, &(&1.name == name))
  end

  defp has_domain_permission?(_, _), do: false

  @spec default_permissions :: list(binary())
  def default_permissions do
    Role
    |> where(is_default: true)
    |> join(:inner, [r], p in assoc(r, :permissions))
    |> select([_, p], p.name)
    |> Repo.all()
  end

  @spec user_permissions(User.t()) :: map
  def user_permissions(user)

  def user_permissions(%User{role: :admin}), do: %{}

  def user_permissions(%User{id: user_id}) do
    do_user_permissions(user_id)
  end

  defp do_user_permissions(user_id) do
    Permission
    |> join(:inner, [p], r in assoc(p, :roles))
    |> join(:inner, [_, r], a in assoc(r, :acl_entries))
    |> join(:left, [_, _, a], ug in "users_groups", on: ug.group_id == a.group_id)
    |> where([_, _, a], a.resource_type == "domain")
    |> where([_, _, a, ug], fragment("coalesce(?, ?)", a.user_id, ug.user_id) == ^user_id)
    |> select([p, _, a, _], {p.name, a.resource_id})
    |> Repo.all()
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  @spec group_names(list(binary)) :: list(binary)
  def group_names(permission_names) do
    Permission
    |> where([p], p.name in ^permission_names)
    |> join(:inner, [p], g in assoc(p, :permission_group))
    |> select([_, g], g.name)
    |> distinct(true)
    |> Repo.all()
  end
end
