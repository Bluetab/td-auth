defmodule TdAuth.Repo.Migrations.AddDescriptionFieldToAclEntry do
  use Ecto.Migration

  def change do
    alter table(:acl_entries) do
       add :description, :string
     end
  end
end
