defmodule TdAuth.Permissions.Permission do
  @moduledoc """
  Ecto schema for permission groups.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Permissions.PermissionGroup

  schema "permissions" do
    field(:name, :string)
    belongs_to(:permission_group, PermissionGroup)

    timestamps()
  end

  def changeset(%__MODULE__{} = permission, params) do
    permission
    |> cast(params, [:name, :permission_group_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
