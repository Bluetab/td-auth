defmodule TdAuth.Accounts.User do
  @moduledoc """
  Ecto schema for users.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdAuth.Accounts.Group
  alias TdAuth.Permissions.AclEntry

  @derive {Jason.Encoder, only: [:id, :user_name]}
  schema "users" do
    field(:password_hash, :string)
    field(:user_name, :string)
    field(:password, :string, virtual: true)
    field(:is_admin, :boolean, default: false, virtual: true)
    field(:is_protected, :boolean, default: false)
    field(:email, :string)
    field(:full_name, :string, default: "")
    field(:role, Ecto.Enum, values: [:admin, :user, :service], default: :user)
    has_many(:acl_entries, AclEntry)
    many_to_many(:groups, Group, join_through: "users_groups", on_replace: :delete)

    timestamps()
  end

  def changeset(params), do: changeset(%__MODULE__{}, params)

  def changeset(%__MODULE__{} = user, params) do
    user
    |> cast(params, [:user_name, :role, :is_admin, :is_protected, :email, :full_name])
    |> cast(params, [:password], empty_values: [])
    |> validate_required([:user_name, :email])
    |> validate_length(:password, min: 6)
    |> put_pass_hash()
    |> update_change(:user_name, &String.downcase/1)
    |> put_groups(params)
    |> put_role()
    |> unique_constraint(:user_name)
  end

  defp put_role(%Changeset{valid?: true} = changeset) do
    case Changeset.fetch_change(changeset, :is_admin) do
      {:ok, true} -> Changeset.put_change(changeset, :role, :admin)
      _ -> changeset
    end
  end

  defp put_role(%Changeset{} = changeset), do: changeset

  defp put_groups(%Changeset{valid?: true} = changeset, %{"groups" => groups}) do
    put_assoc(changeset, :groups, groups)
  end

  defp put_groups(%Changeset{} = changeset, _), do: changeset

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    hash = Bcrypt.add_hash(password)
    change(changeset, hash)
  end

  defp put_pass_hash(changeset), do: changeset

  def check_password(user, password) do
    case user do
      nil -> Bcrypt.no_user_verify()
      _ -> Bcrypt.check_pass(user, password)
    end
  end
end
