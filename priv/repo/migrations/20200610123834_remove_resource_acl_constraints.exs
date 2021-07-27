defmodule TdAuth.Repo.Migrations.RemoveResourceAclConstraints do
  use Ecto.Migration

  def up do
    drop(
      index(:acl_entries, [:user_id, :resource_type, :resource_id], name: :unique_resource_user)
    )

    drop(
      index(:acl_entries, [:group_id, :resource_type, :resource_id], name: :unique_resource_group)
    )
  end

  def down do
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
  end
end
