defmodule TdAuth.Repo.Migrations.AddIsProtected do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:is_protected, :boolean, default: false)
    end
  end
end
