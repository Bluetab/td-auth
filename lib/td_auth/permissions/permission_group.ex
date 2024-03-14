defmodule TdAuth.Permissions.PermissionGroup do
  @moduledoc """
  Ecto schema for permission groups.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Permissions.Permission

  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)

  schema "permission_groups" do
    field(:name, :string)
    has_many(:permissions, Permission, on_replace: :nilify)

    timestamps()
  end

  def changeset_external(%__MODULE__{} = permission_group, params) do
    permission_group
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

  def changeset(%__MODULE__{} = permission_group, params) do
    permission_group
    |> cast(params, [:name])
    |> validate_required(:name)
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

  defp validate_name(%{changes: %{name: name}} = changeset) do
    if String.starts_with?(name, @custom_prefix) do
      changeset
    else
      add_error(
        changeset,
        :name,
        "External permission group creation requires a name starting with '#{@custom_prefix}'"
      )
    end
  end

  defp validate_name(changeset), do: changeset
end
