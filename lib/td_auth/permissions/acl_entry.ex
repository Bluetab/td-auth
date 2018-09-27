defmodule TdAuth.Permissions.AclEntry do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias TdAuth.Accounts
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdAuth.Repo

  schema "acl_entries" do
    field(:principal_id, :integer)
    field(:principal_type, :string)
    field(:resource_id, :integer)
    field(:resource_type, :string)
    belongs_to(:role, Role)

    timestamps()
  end

  @doc false
  def changeset(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> cast(attrs, [:principal_type, :principal_id, :resource_type, :resource_id, :role_id])
    |> validate_required([:principal_type, :principal_id, :resource_type, :resource_id, :role_id])
    |> validate_inclusion(:principal_type, ["user", "group"])
    |> validate_inclusion(:resource_type, ["domain"])
    |> unique_constraint(:unique_principal_resource, name: :principal_resource_index)
  end

  @doc """
  Returns the list of acl_entries.

  ## Examples

      iex> list_acl_entries()
      [%Acl_entry{}, ...]

  """
  def list_acl_entries do
    Repo.all(AclEntry)
  end

  @doc """
    Returns a list of users-role with acl_entries in the domain and role passed as argument

    This return acl with resource type domain and  principal types user or group
  """
  def list_acl_entries(%{domain: domain, role: role}) do
    Repo.all(
      from(
        acl_entry in AclEntry,
        where:
          acl_entry.resource_type == "domain" and acl_entry.resource_id == ^domain.id and
            acl_entry.role_id == ^role.id
      )
    )
  end

  @doc """
  Returns a list of acl_entries relating to a specified resource type and id.
  """
  def list_acl_entries(%{resource_type: type, resource_id: id}) do
    list_acl_entries(%{resource_type: type, resource_id: id}, :role)
  end

  @doc """
  Returns a list of acl_entries relating to a specified resource type and id., configurable preloading
  """
  def list_acl_entries(%{resource_type: type, resource_id: id}, preload) do
    acl_entries =
      Repo.all(
        from(
          acl_entry in AclEntry,
          where: acl_entry.resource_type == ^type and acl_entry.resource_id == ^id
        )
      )

    acl_entries |> Repo.preload(preload)
  end

  def list_user_roles(%{resource_type: type, resource_id: id}) do
    %{resource_type: type, resource_id: id}
    |> list_acl_entries()
    |> Enum.map(&role_with_users/1)
    |> Enum.group_by(& &1.role_name, & &1.users)
    |> Enum.map(fn {role, users} -> {role, Enum.uniq_by(Enum.concat(users), & &1.id)} end)
  end

  def role_with_users(%AclEntry{role: role, principal_type: "user", principal_id: user_id}) do
    user = Accounts.get_user!(user_id)
    %{role_name: role.name, users: [user]}
  end

  def role_with_users(%AclEntry{role: role, principal_type: "group", principal_id: group_id}) do
    users = Accounts.list_users_by_group_id(group_id)
    %{role_name: role.name, users: users}
  end

  @doc """

  """
  def list_acl_entries_by_principal(%{principal_id: principal_id, principal_type: principal_type}) do
    acl_entries =
      Repo.all(
        from(
          acl_entry in AclEntry,
          where:
            acl_entry.principal_type == ^principal_type and
              acl_entry.principal_id == ^principal_id
        )
      )

    acl_entries |> Repo.preload(role: [:permissions])
  end

  def list_acl_entries_by_user(%{user_id: user_id}) do
    list_acl_entries_by_principal(%{principal_id: user_id, principal_type: "user"})
  end

  def list_acl_entries_by_group(%{group_id: group_id}) do
    list_acl_entries_by_principal(%{principal_id: group_id, principal_type: "group"})
  end

  def list_acl_entries_by_user_with_groups(%{user_id: user_id, gids: gids}) do
    user_acl_entries = list_acl_entries_by_user(%{user_id: user_id})

    group_acl_entries =
      gids
      |> Enum.flat_map(&list_acl_entries_by_group(%{group_id: &1}))

    user_acl_entries ++ group_acl_entries
  end

  @doc """
  Gets a single acl_entry.

  Raises `Ecto.NoResultsError` if the Acl entry does not exist.

  ## Examples

      iex> get_acl_entry!(123)
      %Acl_entry{}

      iex> get_acl_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_acl_entry!(id), do: Repo.get!(AclEntry, id)

  @doc """
  Creates a acl_entry.

  ## Examples

      iex> create_acl_entry(%{field: value})
      {:ok, %Acl_entry{}}

      iex> create_acl_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_acl_entry(attrs \\ %{}) do
    %AclEntry{}
    |> AclEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a acl_entry.

  ## Examples

      iex> update_acl_entry(acl_entry, %{field: new_value})
      {:ok, %Acl_entry{}}

      iex> update_acl_entry(acl_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_acl_entry(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> AclEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Acl_entry.

  ## Examples

      iex> delete_acl_entry(acl_entry)
      {:ok, %Acl_entry{}}

      iex> delete_acl_entry(acl_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_acl_entry(%AclEntry{} = acl_entry) do
    Repo.delete(acl_entry)
  end

  def delete_acl_entries(params, options \\ %{}) do
    fields = AclEntry.__schema__(:fields)
    dynamic = filter(params, fields, options)

    query =
      from(
        p in AclEntry,
        where: ^dynamic
      )
    query |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking acl_entry changes.

  ## Examples

      iex> change_acl_entry(acl_entry)
      %Ecto.Changeset{source: %Acl_entry{}}

  """
  def change_acl_entry(%AclEntry{} = acl_entry) do
    AclEntry.changeset(acl_entry, %{})
  end

  @doc """

  """
  def get_acl_entry_by_principal_and_resource(%{
        principal_type: principal_type,
        principal_id: principal_id,
        resource_type: resource_type,
        resource_id: resource_id
      }) do
    Repo.get_by(
      AclEntry,
      principal_type: principal_type,
      principal_id: principal_id,
      resource_type: resource_type,
      resource_id: resource_id
    )
  end

  @doc """
  Returns acl entry for an user and domain
  """
  def get_acl_entry_by_principal_and_resource(%{
        principal_type: principal_type,
        principal_id: principal_id,
        domain: domain
      }) do
    Repo.get_by(
      AclEntry,
      principal_type: principal_type,
      principal_id: principal_id,
      resource_type: "domain",
      resource_id: domain.id
    )
  end

  def acl_matches?(%{principal_type: "user", principal_id: user_id}, user_id, _group_ids),
    do: true

  def acl_matches?(%{principal_type: "group", principal_id: group_id}, _user_id, group_ids) do
    group_ids
    |> Enum.any?(&(&1 == group_id))
  end

  def acl_matches?(_, _, _), do: false

  defp filter(params, fields, options) do
    dynamic = true

    Enum.reduce(Map.keys(params), dynamic, fn x, acc ->
      key_as_atom = if is_binary(x), do: String.to_atom(x), else: x
      param_value = Map.get(params, x)
      case Enum.member?(fields, key_as_atom) do
        true -> buid_dynamic_condition(key_as_atom, param_value, acc, options)
        false -> acc
      end
    end)
  end

  defp buid_dynamic_condition(param_key, param_value, acc, options) when is_list(param_value) do
    case Map.get(options, param_key) do
      :negative -> dynamic([p], not field(p, ^param_key) in ^param_value and ^acc)
      _ -> dynamic([p], field(p, ^param_key) in ^param_value and ^acc)
    end
  end

  defp buid_dynamic_condition(param_key, param_value, acc, options) do
    case Map.get(options, param_key) do
      :negative -> dynamic([p], field(p, ^param_key) != ^param_value and ^acc)
      _ -> dynamic([p], field(p, ^param_key) == ^param_value and ^acc)
    end
  end

end
