defmodule TdAuth.Repo.Migrations.MatchFkIdColumns do
  use Ecto.Migration

  def up do
    alter table(:acl_entries) do
      modify(:resource_id, :bigint)
    end
  end

  def down do
    alter table(:acl_entries) do
      modify(:resource_id, :int)
    end
  end
end
