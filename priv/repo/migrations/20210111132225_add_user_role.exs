defmodule TdAuth.Repo.Migrations.AddUserType do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE role_type AS ENUM ('admin', 'user', 'service')")

    alter table("users") do
      add :role, :role_type, default: "user", null: false
    end
  end

  def down do
    alter table("users") do
      remove :role
    end

    execute("DROP TYPE role_type")
  end
end
