defmodule TdAuth.Repo.Migrations.CreateAclEntriesTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:acl_entries) do
      add(:principal_type, :string)
      add(:principal_id, :integer)
      add(:resource_type, :string)
      add(:resource_id, :integer)
      add(:role_id, references(:roles, on_delete: :nothing))

      timestamps()
    end

    create_if_not_exists(index(:acl_entries, [:role_id]))
    create_if_not_exists(index(:acl_entries, [:resource_type, :resource_id]))
    create_if_not_exists(index(:acl_entries, [:principal_type, :principal_id]))
  end
end
