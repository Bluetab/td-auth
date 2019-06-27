defmodule TdAuth.Accounts.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Repo

  @hash Application.get_env(:td_auth, :hashing_module)

  @derive {Jason.Encoder, only: [:id, :user_name, :is_admin]}
  schema "users" do
    field(:password_hash, :string)
    field(:user_name, :string)
    field(:password, :string, virtual: true)
    field(:is_admin, :boolean, default: false)
    field(:is_protected, :boolean, default: false)
    field(:email, :string)
    field(:full_name, :string, default: "")
    many_to_many(:groups, Group, join_through: "users_groups", on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:user_name, :password, :is_admin, :is_protected, :email, :full_name])
    |> validate_required([:user_name, :email])
    |> downcase_value
    |> unique_constraint(:user_name)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: @hash.hashpwsalt(password))
  end

  defp put_pass_hash(changeset), do: changeset

  def registration_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> put_assoc(:groups, parse_groups(params["groups"]))
    |> cast(params, [:password])
    |> put_pass_hash()
  end

  def update_changeset(%User{} = user, %{"groups" => groups} = attrs) do
    user
    |> Repo.preload(:groups)
    |> changeset(attrs)
    |> put_assoc(:groups, parse_groups(groups))
  end

  def update_changeset(%User{} = user, attrs) do
    changeset(user, attrs)
  end

  def check_password(user, password) do
    case user do
      nil -> @hash.dummy_checkpw()
      _ -> @hash.checkpw(password, user.password_hash)
    end
  end

  def downcase_value(changeset) do
    update_change(changeset, :user_name, &String.downcase/1)
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
      _ -> groups |> Enum.map(&get_or_insert_group/1)
    end
  end

  defp get_or_insert_group(%{"name" => name}) do
    Accounts.get_group_by_name(name) ||
      case Accounts.create_group(%{name: name}) do
        {:ok, %Group{} = group} -> group
        %Group{} = group -> group
        error -> error
      end
  end

  defp get_or_insert_group(name) do
    Accounts.get_group_by_name(name) ||
      case Accounts.create_group(%{name: name}) do
        {:ok, %Group{} = group} -> group
        %Group{} = group -> group
        error -> error
      end
  end
end
