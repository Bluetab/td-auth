defmodule TdAuth.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Permissions.Role
  alias TdAuth.Repo

  @default_preloads :permission_group
  @allowed_resource_types ["domain", "structure"]

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

  def create_external_permission(attrs \\ %{}) do
    attrs
    |> Permission.changeset_external()
    |> Repo.insert()
  end

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

  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  def cache_session_permissions(permissions, %{"jti" => jti, "exp" => exp} = _claims) do
    do_cache_session_permissions(permissions, jti, exp)
  end

  defp do_cache_session_permissions(permissions, _jti, _exp) when permissions == %{}, do: :ok

  defp do_cache_session_permissions(permissions, jti, exp) do
    TdCache.Permissions.cache_session_permissions!(jti, exp, permissions)
  end

  def list_permission_groups do
    Repo.all(PermissionGroup)
  end

  def get_permission_group!(id) do
    Repo.get!(PermissionGroup, id)
  end

  def get_permission_group_by_name(name), do: Repo.get_by(PermissionGroup, name: name)

  def create_external_permission_group(attrs \\ %{}) do
    attrs
    |> PermissionGroup.changeset_external()
    |> Repo.insert()
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

  def update_to_external_permission_group(%PermissionGroup{} = permission_group, params) do
    permission_group
    |> PermissionGroup.changeset_external(params)
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
    |> where([_, _, a], a.resource_type in @allowed_resource_types)
    |> where([_, _, a, ug], fragment("coalesce(?, ?)", a.user_id, ug.user_id) == ^user_id)
    |> select([p, _, a, _], {a.resource_type, p.name, a.resource_id})
    |> Repo.all()
    |> Enum.reduce(%{}, fn {resource_type, permission_name, resource_id}, acc ->
      acc_case = Map.get(acc, resource_type, %{})

      Map.put(
        acc,
        resource_type,
        Map.put(
          acc_case,
          permission_name,
          Map.get(acc_case, permission_name, []) ++ [resource_id]
        )
      )
    end)
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
