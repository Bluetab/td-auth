defmodule TdAuth.Repo.Migrations.AddIdTimestampsToRolesPermissions do
  use Ecto.Migration

  def change do
    alter table(:roles_permissions) do
      add(:id, :bigserial, primary_key: true)
      timestamps(default: "#{DateTime.utc_now()}")
    end
  end
end
