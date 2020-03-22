defmodule TdAuth.Accounts.User do
  @moduledoc """
  Ecto schema for users.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Repo

  @derive {Jason.Encoder, only: [:id, :user_name, :is_admin]}
  schema "users" do
    field(:password_hash, :string)
    field(:user_name, :string)
    field(:password, :string, virtual: true)
    field(:is_admin, :boolean, default: false)
    field(:is_protected, :boolean, default: false)
    field(:email, :string)
    field(:full_name, :string, default: "")
    has_many(:acl_entries, AclEntry)
    many_to_many(:groups, Group, join_through: "users_groups", on_replace: :delete)

    timestamps()
  end

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:user_name, :password, :is_admin, :is_protected, :email, :full_name])
    |> validate_required([:user_name, :email])
    |> update_change(:user_name, &String.downcase/1)
    |> unique_constraint(:user_name)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    hash = Bcrypt.add_hash(password)
    change(changeset, hash)
  end

  defp put_pass_hash(changeset), do: changeset

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> put_assoc(:groups, parse_groups(params["groups"]))
    |> cast(params, [:password])
    |> put_pass_hash()
  end

  def update_changeset(%User{} = user, %{"groups" => groups} = params) do
    user
    |> Repo.preload(:groups)
    |> changeset(params)
    |> put_assoc(:groups, parse_groups(groups))
  end

  def update_changeset(%User{} = user, params) do
    changeset(user, params)
  end

  def check_password(user, password) do
    case user do
      nil -> Bcrypt.no_user_verify()
      _ -> Bcrypt.check_pass(user, password)
    end
  end

  def link_to_groups_changeset(user, groups) do
    user
    |> change
    |> put_assoc(:groups, parse_groups(groups))
  end

  def delete_group_changeset(user, group) do
    groups = Enum.filter(user.groups, &(&1.name != group.name))

    user
    |> change()
    |> put_assoc(:groups, groups)
  end

  defp parse_groups(groups) do
    case groups do
      nil -> []
      [] -> []
      _ -> Enum.map(groups, &get_or_insert_group/1)
    end
  end

  defp get_or_insert_group(%{"name" => name}) do
    get_or_insert_group(name)
  end

  defp get_or_insert_group(name) when is_binary(name) do
    Accounts.get_group_by_name(name) ||
      case Accounts.create_group(%{name: name}) do
        {:ok, %Group{} = group} -> group
        %Group{} = group -> group
        error -> error
      end
  end
end
