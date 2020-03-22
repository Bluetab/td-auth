defmodule TdAuth.Accounts.Group do
  @moduledoc """
  Ecto schema for user groups.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.AclEntry

  schema "groups" do
    field(:name, :string)
    field(:description, :string)
    has_many(:acl_entries, AclEntry)
    many_to_many(:users, User, join_through: "users_groups", on_replace: :delete)

    timestamps()
  end

  def changeset(%__MODULE__{} = group, params) do
    group
    |> cast(params, [:name, :description])
    |> validate_required([:name])
    |> put_users(params)
    |> unique_constraint(:name)
  end

  defp put_users(%Changeset{valid?: true} = changeset, %{"users" => users}) do
    put_assoc(changeset, :users, users)
  end

  defp put_users(%Changeset{} = changeset, _), do: changeset
end
