defmodule TdAuth.Repo.Migrations.AddAclEntriesGroupIdUserId do
  use Ecto.Migration

  def change do
    execute(
      "delete from acl_entries where principal_type='group' and principal_id not in (select id from groups)",
      fn -> :ok end
    )

    execute(
      "delete from acl_entries where principal_type='user' and principal_id not in (select id from users)",
      fn -> :ok end
    )

    alter table(:acl_entries) do
      add(:group_id, references("groups", on_delete: :delete_all))
      add(:user_id, references("users", on_delete: :delete_all))
    end

    execute(
      "update acl_entries set group_id = principal_id where principal_type = 'group'",
      fn -> :ok end
    )

    execute(
      "update acl_entries set user_id = principal_id where principal_type = 'user'",
      fn -> :ok end
    )

    create(
      unique_index(:acl_entries, [:user_id, :resource_type, :resource_id],
        where: "group_id is null",
        name: :unique_resource_user
      )
    )

    create(
      unique_index(:acl_entries, [:group_id, :resource_type, :resource_id],
        where: "user_id is null",
        name: :unique_resource_group
      )
    )

    create(constraint("acl_entries", :user_xor_group, check: "num_nulls(user_id, group_id) = 1"))
  end
end
