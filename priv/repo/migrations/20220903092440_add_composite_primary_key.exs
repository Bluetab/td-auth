defmodule TdAuth.Repo.Migrations.AddCompositePrimaryKey do
  use Ecto.Migration

  def up do
    alter table(:roles_permissions) do
      modify(:role_id, :bigint, primary_key: true)
      modify(:permission_id, :bigint, primary_key: true)
    end

    drop(unique_index(:roles_permissions, [:role_id, :permission_id]))
  end

  def down do
    create(unique_index(:roles_permissions, [:role_id, :permission_id]))
    drop(constraint(:roles_permissions, "roles_permissions_pkey"))
  end
end
