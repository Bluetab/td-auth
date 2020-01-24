defmodule TdAuth.Permissions.PermissionGroup do
  @moduledoc """
  Group of permissions
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.PermissionGroup

  schema "permission_groups" do
    field(:name, :string)
    has_many(:permissions, Permission)

    timestamps()
  end

  @doc false
  def changeset(permission_group, attrs) do
    permission_group
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def delete_changeset(%PermissionGroup{} = permission_group) do
    permission_group
    |> change()
    |> foreign_key_constraint(:permissions,
      name: :permissions_permission_group_id_fkey,
      message: "group.delete.existing.permissions"
    )
  end
end
