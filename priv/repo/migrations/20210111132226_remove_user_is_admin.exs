defmodule TdAuth.Repo.Migrations.RemoveUserIsAdmin do
  use Ecto.Migration

  def change do
    execute("update users set role='admin' where is_admin=TRUE", "")

    alter table("users") do
      remove :is_admin
    end
  end

  def down do
    alter table("users") do
      add :is_admin, :boolean, default: false, null: false
    end

    execute("update users set is_admin=TRUE where role='admin'")
  end
end
