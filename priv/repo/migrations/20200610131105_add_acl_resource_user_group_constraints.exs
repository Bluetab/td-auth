defmodule TdAuth.Repo.Migrations.AddAclResourceUserGroupConstraints do
  use Ecto.Migration

  def up do
    create(
      unique_index(:acl_entries, [:user_id, :resource_type, :resource_id, :role_id],
        where: "group_id is null",
        name: :unique_resource_user_role
      )
    )

    create(
      unique_index(:acl_entries, [:group_id, :resource_type, :resource_id, :role_id],
        where: "user_id is null",
        name: :unique_resource_group_role
      )
    )
  end

  def down do
    drop(
      index(:acl_entries, [:user_id, :resource_type, :resource_id, :role_id],
        name: :unique_resource_user_role
      )
    )

    drop(
      index(:acl_entries, [:group_id, :resource_type, :resource_id, :role_id],
        name: :unique_resource_group_role
      )
    )
  end
end
