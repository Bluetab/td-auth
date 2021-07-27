defmodule TdAuth.Repo.Migrations.DeleteUsersIsProtected do
  use Ecto.Migration

  def up do
    alter table("users") do
      remove(:is_protected)
    end
  end

  def down do
    alter table("users") do
      add(:is_protected, :boolean, default: false, null: false)
    end
  end
end
