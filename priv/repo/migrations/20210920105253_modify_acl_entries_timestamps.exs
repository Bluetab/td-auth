defmodule TdAuth.Repo.Migrations.ModifyAclEntriesTimestamps do
  use Ecto.Migration

  def change do
    alter table("acl_entries") do
      modify(:inserted_at, :utc_datetime_usec, from: :utc_datetime)
      modify(:updated_at, :utc_datetime_usec, from: :utc_datetime)
    end
  end
end
