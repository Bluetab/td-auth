defmodule TdAuth.Accounts.Group do
  use Ecto.Schema
  import Ecto.Changeset
  alias TdAuth.Accounts.Group
  # alias TdAuth.Accounts.User


  schema "groups" do
    field :name, :string
    # many_to_many :users, User, join_through: "users_groups"

    timestamps()
  end

  @doc false
  def changeset(%Group{} = group, attrs) do
    group
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
