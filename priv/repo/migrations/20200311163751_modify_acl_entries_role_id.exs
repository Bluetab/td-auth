defmodule TdAuth.Repo.Migrations.ModifyAclEntriesRoleId do
  use Ecto.Migration

  def up do
    execute("delete from acl_entries where role_id not in (select id from roles)")
    drop(constraint(:acl_entries, :acl_entries_role_id_fkey))

    alter table(:acl_entries) do
      modify(:role_id, references("roles", on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:acl_entries, :acl_entries_role_id_fkey))

    alter table(:acl_entries) do
      modify(:role_id, references("roles", on_delete: :nothing))
    end
  end
end
