defmodule TdAuth.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdAuth.Accounts.User
  @hash Application.get_env(:td_auth, :hashing_module)

  @derive {Poison.Encoder, only: [:id, :user_name, :is_admin]}
  schema "users" do
    field :password_hash, :string
    field :user_name, :string
    field :password, :string, virtual: true
    field :is_admin, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:user_name, :password, :is_admin])
    |> validate_required([:user_name])
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

end
