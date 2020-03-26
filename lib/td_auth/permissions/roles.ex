defmodule TdAuth.Permissions.Roles do
  @moduledoc """
  The Roles context.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias TdAuth.Permissions.Role
  alias TdAuth.Repo

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Repo.all(Role)
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id), do: Repo.get!(Role, id)

  @doc """
  Gets a single role.

  ## Examples

      iex> get_role(123)
      %Role{}

      iex> get_role(456)
      nil

  """
  def get_role(id), do: Repo.get(Role, id)

  @doc """
  Creates a role.

  Returns an `Ecto.Multi` result with the following keys:

    * `role` - The created role
    * `unset_default` - The result of the update_all operation on the current
      default role

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %{role: %Role{}}}

      iex> create_role(%{field: bad_value})
      {:error, :role, %Ecto.Changeset{}, %{}}

  """
  def create_role(params \\ %{}) do
    case Role.changeset(params) do
      changeset = %Changeset{} ->
        Multi.new()
        |> unset_default(changeset)
        |> Multi.insert(:role, changeset)
        |> Repo.transaction()
    end
  end

  @doc """
  Updates a role.

  Returns an `Ecto.Multi` result with the following keys:

    * `role` - The created role
    * `unset_default` - The result of the update_all operation on the current
      default role

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %{role: %Role{}}}

      iex> update_role(role, %{field: bad_value})
      {:error, :role, %Ecto.Changeset{}, %{}}

  """
  def update_role(%Role{} = role, params) do
    case Role.changeset(role, params) do
      changeset = %Changeset{} ->
        Multi.new()
        |> unset_default(changeset)
        |> Multi.update(:role, changeset)
        |> Repo.transaction()
    end
  end

  @doc """
  Deletes a Role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_role(%Role{} = role) do
    Repo.delete(role)
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

  @doc """
  Associate Permissions to a Role.

  ## Examples

      iex> put_permissions!()
      %Role{}

  """
  def put_permissions(%Role{} = role, permissions) do
    role
    |> Repo.preload(:permissions)
    |> Changeset.change()
    |> Changeset.put_assoc(:permissions, permissions)
    |> Repo.update!()
  end

  @doc """
  Returns the list of Permissions asociated to a Role.

  ## Examples

      iex> get_role_permissions()
      [%Permission{}, ...]

  """
  def get_role_permissions(%Role{} = role) do
    role
    |> Repo.preload(permissions: :permission_group)
    |> Map.get(:permissions)
  end

  defp unset_default(%Multi{} = multi, %Changeset{} = changeset) do
    import Ecto.Query

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

  defp reduce_opts(queryable, opts) do
    Enum.reduce(opts, queryable, fn
      {:is_default, is_default}, q -> where(q, is_default: ^is_default)
      {:name, name}, q -> where(q, name: ^name)
      {:preload, preloads}, q -> preload(q, ^preloads)
      _, q -> q
    end)
  end
end
