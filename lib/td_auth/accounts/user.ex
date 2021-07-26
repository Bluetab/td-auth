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
    field(:old_password, :string, virtual: true)
    field(:email, :string)
    field(:full_name, :string, default: "")
    field(:role, Ecto.Enum, values: [:admin, :user, :service], default: :user)
    has_many(:acl_entries, AclEntry)
    many_to_many(:groups, Group, join_through: "users_groups", on_replace: :delete)

    timestamps()
  end

  def changeset(params), do: changeset(%__MODULE__{}, params)

  def changeset(%__MODULE__{} = user, params, keep_groups \\ false) do
    user
    |> cast(params, [:user_name, :role, :email, :full_name])
    |> cast(params, [:password, :old_password], empty_values: [])
    |> validate_required(:user_name)
    |> validate_length(:password, min: 6)
    |> validate_old_password()
    |> put_pass_hash()
    |> update_change(:user_name, &String.downcase/1)
    |> put_groups(user.groups, keep_groups, params)
    |> put_role()
    |> unique_constraint(:user_name)
  end

  defp validate_old_password(
         %{changes: %{password: _password, old_password: old_password}} = changeset
       ) do
    stored_hash = get_field(changeset, :password_hash)

    if Bcrypt.verify_pass(old_password, stored_hash) do
      changeset
    else
      add_error(changeset, :old_password, "Invalid old password")
    end
  end

  defp validate_old_password(changeset), do: changeset

  defp put_role(%Changeset{valid?: true} = changeset) do
    case Changeset.fetch_change(changeset, :is_admin) do
      {:ok, true} -> Changeset.put_change(changeset, :role, :admin)
      _ -> changeset
    end
  end

  defp put_role(%Changeset{} = changeset), do: changeset

  defp put_groups(%Changeset{valid?: true} = changeset, _existing_groups, false, %{
         "groups" => groups
       }) do
    put_assoc(changeset, :groups, groups)
  end

  defp put_groups(%Changeset{valid?: true} = changeset, existing_groups, true, %{
         "groups" => groups
       }) do
    put_assoc(changeset, :groups, existing_groups ++ groups)
  end

  defp put_groups(%Changeset{} = changeset, _existing_groups, _, _), do: changeset

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    hash = Bcrypt.add_hash(password)
    change(changeset, hash)
  end

  defp put_pass_hash(changeset), do: changeset

  def check_password(nil, _password), do: Bcrypt.no_user_verify()

  def check_password(user, password), do: Bcrypt.check_pass(user, password)
end
