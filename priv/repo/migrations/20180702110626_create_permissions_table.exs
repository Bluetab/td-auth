defmodule TdAuth.Repo.Migrations.CreatePermissionsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:permissions) do
      add :name, :string, null: false
      timestamps()
    end

    create_if_not_exists unique_index(:permissions, [:name])
  end
end
