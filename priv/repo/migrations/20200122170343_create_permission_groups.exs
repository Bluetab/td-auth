defmodule TdAuth.Repo.Migrations.CreatePermissionGroups do
  use Ecto.Migration

  def change do
    create table(:permission_groups) do
      add :name, :string, null: false

      timestamps()
    end

    create_if_not_exists unique_index(:permission_groups, [:name])
  end
end
