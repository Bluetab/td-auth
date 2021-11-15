defmodule TdAuth.Repo.Migrations.AddExternalIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:external_id, :string)
    end

    create(unique_index(:users, [:external_id]))
  end
end
