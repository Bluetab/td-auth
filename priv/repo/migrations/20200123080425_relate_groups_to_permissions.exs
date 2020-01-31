defmodule TdAuth.Repo.Migrations.RelateGroupsToPermissions do
  use Ecto.Migration

  def change do
    alter table(:permissions) do
      add :permission_group_id, references(:permission_groups), null: true
    end
  end
end
