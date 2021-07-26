defmodule TdAuth.Repo.Migrations.AddDefaultRole do
  use Ecto.Migration

  def up do
    alter(table(:roles), do: add(:is_default, :boolean, default: false, null: true))
    flush()
    execute("update roles set is_default = false")
    alter(table(:roles), do: modify(:is_default, :boolean, default: false, null: false))
  end

  def down do
    alter(table(:roles), do: remove(:is_default))
  end
end
