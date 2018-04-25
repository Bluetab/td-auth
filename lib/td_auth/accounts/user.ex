defmodule TdAuth.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdAuth.Accounts.User
  alias TdAuth.Accounts.Group

  @hash Application.get_env(:td_auth, :hashing_module)

  @derive {Poison.Encoder, only: [:id, :user_name, :is_admin]}
  schema "users" do
    field :password_hash, :string
    field :user_name, :string
    field :password, :string, virtual: true
    field :is_admin, :boolean, default: false
    field :is_protected, :boolean, default: false
    field :email, :string
    field :full_name, :string, default: ""
    many_to_many :groups, Group, join_through: "users_groups", on_replace: :delete

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
    |> cast(params, ~w(password))
    #|> unique_constraint(:user_name, message: "User name must be unique")
    |> put_pass_hash()
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

  def delete_group_changeset(user, group) do
    groups = Enum.filter(user.groups, &(&1.name != group.name))
    user
    |> change()
    |> put_assoc(:groups, groups)
  end

end
