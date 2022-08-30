defmodule TdAuth.Permissions.Permission do
  @moduledoc """
  Ecto schema for permission groups.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Permissions.Constants
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Permissions.Role

  @custom_prefix Constants.custom_prefix()

  schema "permissions" do
    field(:name, :string)
    belongs_to(:permission_group, PermissionGroup)
    many_to_many(:roles, Role, join_through: TdAuth.Permissions.RolePermission)

    timestamps()
  end

  def changeset_external(%__MODULE__{} = permission, params) do
    permission
    |> changeset(params)
    |> validate_name()
  end

  def changeset_external(params) do
    params
    |> changeset()
    |> validate_name()
  end

  def changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = permission, params) do
    permission
    |> cast(params, [:name, :permission_group_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:permission_group_id)
  end

  defp validate_name(%{changes: %{name: name}} = changeset) do
    if String.starts_with?(name, @custom_prefix) do
      changeset
    else
      add_error(
        changeset,
        :name,
        "External permission creation requires a name starting with '#{@custom_prefix}'"
      )
    end
  end

  defp validate_name(changeset), do: changeset
end
