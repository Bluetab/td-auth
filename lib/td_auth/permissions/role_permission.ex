defmodule TdAuth.Permissions.RolePermission do
  @moduledoc """
  Ecto schema for Role - Permission relations.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "roles_permissions" do
    belongs_to(:role, TdAuth.Permissions.Role)
    belongs_to(:permission, TdAuth.Permissions.Permission)

    timestamps()
  end

  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(role_permission, params) do
    role_permission
    |> cast(params, [:role_id, :permission_id])
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:permission_id)
  end
end
