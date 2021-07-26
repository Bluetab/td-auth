defmodule TdAuth.Repo.Migrations.CreateRolesTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:roles) do
      add(:name, :string, null: false)
      timestamps()
    end

    create_if_not_exists(unique_index(:roles, [:name]))
  end
end
