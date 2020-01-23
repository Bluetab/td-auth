defmodule TdAuth.Permissions.PermissionGroup do
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAuth.Permissions.Permission

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
end
