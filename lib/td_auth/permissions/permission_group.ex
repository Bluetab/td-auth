defmodule TdAuth.Permissions.PermissionGroup do
  @moduledoc """
  Ecto schema for permission groups.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Permissions.Permission

  schema "permission_groups" do
    field(:name, :string)
    has_many(:permissions, Permission, on_replace: :nilify)

    timestamps()
  end

  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = permission_group, params) do
    permission_group
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def delete_changeset(%__MODULE__{} = permission_group) do
    permission_group
    |> change()
    |> foreign_key_constraint(:permissions,
      name: :permissions_permission_group_id_fkey,
      message: "group.delete.existing.permissions"
    )
  end
end
