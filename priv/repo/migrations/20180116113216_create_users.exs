defmodule TdAuth.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_name, :string, null: false
      add :password_hash, :string
      add :email, :string, null: false
      add :full_name, :string

      timestamps()
    end

  end
end
