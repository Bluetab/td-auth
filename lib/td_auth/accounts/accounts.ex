defmodule TdAuth.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Repo
  alias TdAuth.UserLoader

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(from u in User, where: u.is_protected == false)
  end

  def list_users(ids) do
    Repo.all(from u in User, where: u.id in ^ids)
  end

  def list_users_by_group_id(group_id) do
    group = get_group!(group_id)
    Repo.all(Ecto.assoc(group, :users))
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_name(user_name) do
    User
    |> Repo.get_by(user_name: String.downcase(user_name))
    |> Repo.preload(:groups)
  end

  def exist_user?(user_name) do
    Repo.one(from u in User, select: count(u.id), where: u.user_name == ^user_name) > 0
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    attrs
    |> create_user_nocache
    |> refresh_cache
  end

  @doc """
  Creates a user without updating user cache.
  """
  def create_user_nocache(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
    |> refresh_cache
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    user
      |> Repo.delete()
      |> delete_acl_entries("user")
      |> delete_cache()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups do
    Repo.all(Group)
  end

  def list_groups(ids) do
    Repo.all(from u in Group, where: u.id in ^ids)
  end

  @doc """
  Gets a single group.

  Raises `Ecto.NoResultsError` if the Group does not exist.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group!(id), do: Repo.get!(Group, id)

  @doc """
  Gets a single group.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      nil

  """
  def get_group(id), do: Repo.get(Group, id)

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Group{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def get_group_by_name(name) do
    Repo.get_by(Group, name: name)
  end

  @doc """
  Updates a group.

  ## Examples

      iex> update_group(group, %{field: new_value})
      {:ok, %Group{}}

      iex> update_group(group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    group
    |> Repo.delete()
    |> delete_acl_entries("group")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group changes.

  ## Examples

      iex> change_group(group)
      %Ecto.Changeset{source: %Group{}}

  """
  def change_group(%Group{} = group) do
    Group.changeset(group, %{})
  end

  @doc false
  def delete_group_from_user(%User{} = user, %Group{} = group) do
    user = Repo.preload(user, :groups)
    groups = Enum.filter(user.groups, &(&1.name != group.name))
    user
    |> Changeset.change
    |> Changeset.put_assoc(:groups, groups)
    |> Repo.update()
  end

  @doc false
  def add_groups_to_user(%User{} = user, groups) do
    user
    |> Repo.preload(:groups)
    |> User.link_to_groups_changeset(groups)
    |> Repo.update
  end

  defp delete_acl_entries({:ok, %{id: id} = resource}, principal_type) do
    AclEntry.delete_acl_entries(id, principal_type)
    {:ok, resource}
  end

  defp refresh_cache({:ok, %{id: id} = user}) do
    UserLoader.refresh(id)
    {:ok, user}
  end
  defp refresh_cache(result), do: result
  defp delete_cache({:ok, %{id: id} = user}) do
    UserLoader.delete(id)
    {:ok, user}
  end
  defp delete_cache(result), do: result

end
