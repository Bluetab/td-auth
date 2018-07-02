defmodule TdAuth.Repo.Migrations.CreateRolesPermissionsTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:roles_permissions, primary_key: false) do
      add :role_id, references(:roles, on_delete: :delete_all)
      add :permission_id, references(:permissions, on_delete: :delete_all)
    end

    create_if_not_exists unique_index(:roles_permissions, [:role_id, :permission_id])
  end
end
