defmodule TdAuth.Repo.Migrations.RemoveRoleType do
  use Ecto.Migration

  def up do
    alter table("users") do
      add(:role_temp, :string, null: false, default: "user")
    end

    flush()

    execute("UPDATE users SET role_temp = role")

    alter table("users") do
      remove(:role)
    end

    alter table("users") do
      add(:role, :varchar, null: false, default: "user")
    end

    flush()

    execute("UPDATE users SET role = role_temp")

    alter table("users") do
      remove(:role_temp)
    end

    execute("DROP TYPE role_type")
  end

  def down do
    execute("CREATE TYPE role_type AS ENUM ('admin', 'user', 'service')")
  end
end
