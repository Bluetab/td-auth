defmodule TdAuth.Permissions.AclEntry do
  @moduledoc """
  Ecto schema for ACL Entries.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.Role

  @permitted [
    :description,
    :group_id,
    :resource_id,
    :resource_type,
    :role_id,
    :user_id
  ]

  schema "acl_entries" do
    field(:resource_id, :integer)
    field(:resource_type, :string)
    field(:description, :string)

    belongs_to(:role, Role)
    belongs_to(:user, User)
    belongs_to(:group, Group)

    timestamps()
  end

  @doc """
  Casts a map retaining only permitted parameters
  """
  def changes(%{} = attrs) do
    %__MODULE__{}
    |> cast(attrs, @permitted)
    |> Map.get(:changes)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` applying the given `params` as changes.
  """
  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` to an `%ActEntry{}` applying the given `params` as changes.
  """
  def changeset(%__MODULE__{} = acl_entry, params) do
    acl_entry
    |> cast(params, @permitted)
    |> put_nil_principal(params)
    |> validate_required([:resource_type, :resource_id, :role_id])
    |> validate_length(:description, max: 120)
    |> validate_inclusion(:resource_type, ["domain"])
    |> foreign_key_constraint(:group_id, name: :acl_entries_group_id_fkey)
    |> foreign_key_constraint(:role_id, name: :acl_entries_role_id_fkey)
    |> foreign_key_constraint(:user_id, name: :acl_entries_user_id_fkey)
    |> unique_constraint(:group_id, name: :unique_resource_group)
    |> unique_constraint(:user_id, name: :unique_resource_user)
    |> check_constraint(:group_id, name: :user_xor_group)
  end

  # If `user_id` is specified, `group_id` is changed to nil, and vice versa.
  defp put_nil_principal(%Ecto.Changeset{} = changeset, %{} = params) do
    case changes(params) do
      %{user_id: _, group_id: _} -> changeset
      %{user_id: _} -> put_change(changeset, :group_id, nil)
      %{group_id: _} -> put_change(changeset, :user_id, nil)
      _ -> changeset
    end
  end
end
