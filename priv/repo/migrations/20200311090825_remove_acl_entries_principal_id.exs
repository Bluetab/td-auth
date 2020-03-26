defmodule TdAuth.Repo.Migrations.RemoveAclEntriesPrincipalId do
  use Ecto.Migration

  def change do
    drop(
      index(:acl_entries, [:principal_type, :principal_id, :resource_type, :resource_id],
        name: :principal_resource_index
      )
    )

    drop(index(:acl_entries, [:principal_type, :principal_id]))

    execute(
      fn -> :ok end,
      "update acl_entries set principal_id = coalesce(user_id, group_id), principal_type = case when user_id is null then 'group' else 'user' end"
    )

    alter table(:acl_entries) do
      remove(:principal_id, :integer)
      remove(:principal_type, :string)
    end
  end
end
