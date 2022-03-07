defmodule TdAuth.Permissions.Roles do
  @moduledoc """
  The Roles context.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.RoleLoader
  alias TdAuth.Repo

  @typep multi_result ::
           {:ok, map} | {:error, Multi.name(), any(), %{required(Multi.name()) => any()}}

  @doc "Returns the list of roles"
  def list_roles do
    Repo.all(Role)
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.
  """
  def get_role!(id), do: Repo.get!(Role, id)

  @doc "Gets a single role, returning nil if it doesn't exist."
  def get_role(id), do: Repo.get(Role, id)

  @doc """
  Creates a role.

  Returns an `Ecto.Multi` result with the following keys:

    * `role` - The created role
    * `unset_default` - The result of the update_all operation on the current
      default role
  """
  @spec create_role(map) :: multi_result
  def create_role(%{} = params) do
    changeset = Role.changeset(params)

    Multi.new()
    |> unset_default(changeset)
    |> Multi.insert(:role, changeset)
    |> Repo.transaction()
    |> maybe_refresh_cache()
  end

  @doc """
  Updates a role.

  Returns an `Ecto.Multi` result with the following keys:

    * `role` - The created role
    * `unset_default` - The result of the update_all operation on the current
      default role
  """
  @spec update_role(Role.t(), map) :: multi_result
  def update_role(%Role{} = role, params) do
    changeset = Role.changeset(role, params)

    Multi.new()
    |> unset_default(changeset)
    |> Multi.update(:role, changeset)
    |> Repo.transaction()
    |> maybe_refresh_cache()
  end

  @doc "Deletes a Role"
  @spec delete_role(Role.t()) :: multi_result
  def delete_role(%Role{} = role) do
    Multi.new()
    |> Multi.delete(:role, role)
    |> Repo.transaction()
    |> maybe_refresh_cache()
  end

  @doc """
  Returns a Role matching the specified options. The following options are
  currently handled:

    * `is_default` - Matches the default role if value is `true`
    * `name` - Matches the role name
    * `preload` - Specifies the associations to be preloaded
  """
  def get_by(opts) do
    Role
    |> reduce_opts(opts)
    |> Repo.one()
  end

  @doc """
  Returns a Role with the specified name, creating it if it doesn't already exist
  """
  def get_or_create(name) do
    case get_by(name: name) do
      nil ->
        {:ok, role} = create_role(%{name: name})
        role

      role ->
        role
    end
  end

  @doc "Associate Permissions to a Role"
  @spec put_permissions(Role.t(), list) :: multi_result
  def put_permissions(%Role{} = role, permissions) do
    changeset =
      role
      |> Repo.preload(:permissions)
      |> Changeset.change()
      |> Changeset.put_assoc(:permissions, permissions)

    Multi.new()
    |> Multi.update(:role, changeset)
    |> Repo.transaction()
    |> maybe_refresh_cache()
  end

  @doc "Returns the list of Permissions asociated to a Role"
  def get_role_permissions(%Role{} = role) do
    role
    |> Repo.preload(permissions: :permission_group)
    |> Map.get(:permissions)
  end

  defp unset_default(%Multi{} = multi, %Changeset{} = changeset) do
    case Changeset.fetch_change(changeset, :is_default) do
      {:ok, true} ->
        Multi.update_all(
          multi,
          :unset_default,
          from(r in Role, where: r.is_default, select: r),
          set: [is_default: false, updated_at: DateTime.utc_now()]
        )

      _ ->
        multi
    end
  end

  defp maybe_refresh_cache({:ok, _} = res) do
    RoleLoader.load_roles()
    res
  end

  defp maybe_refresh_cache(res), do: res

  defp reduce_opts(queryable, opts) do
    Enum.reduce(opts, queryable, fn
      {:is_default, is_default}, q -> where(q, is_default: ^is_default)
      {:name, name}, q -> where(q, name: ^name)
      {:preload, preloads}, q -> preload(q, ^preloads)
      _, q -> q
    end)
  end
end
