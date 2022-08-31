defmodule TdAuth.Repo.Migrations.RemoveIdTimestampsToRolesPermissions do
  use Ecto.Migration

  def change do
    alter table(:roles_permissions) do
      remove(:id, :bigserial)
      remove(:inserted_at, :timestamp)
      remove(:updated_at, :timestamp)
    end

    create_if_not_exists(unique_index(:roles_permissions, [:role_id, :permission_id]))
  end
end
