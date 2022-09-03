defmodule TdAuth.Permissions.RolePermission do
  @moduledoc """
  Ecto schema for Role - Permission relations.
  """
  use Ecto.Schema

  import Ecto.Changeset
  @primary_key false
  schema "roles_permissions" do
    belongs_to(:role, TdAuth.Permissions.Role, primary_key: true)
    belongs_to(:permission, TdAuth.Permissions.Permission, primary_key: true)
  end

  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(role_permission, params) do
    role_permission
    |> cast(params, [:role_id, :permission_id])
    |> unique_constraint([:role_id, :permission_id], name: :roles_permissions_pkey)
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:permission_id)
  end
end
