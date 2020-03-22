defmodule TdAuth.Permissions.Role do
  @moduledoc """
  Ecto schema for roles.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias TdAuth.Permissions.Permission

  schema "roles" do
    field(:name, :string)
    field(:is_default, :boolean, default: false)

    many_to_many(:permissions, Permission,
      join_through: "roles_permissions",
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps()
  end

  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = role, params) do
    role
    |> Changeset.cast(params, [:name, :is_default])
    |> Changeset.validate_required([:name, :is_default])
    |> Changeset.unique_constraint(:is_default)
    |> Changeset.unique_constraint(:name)
  end
end
