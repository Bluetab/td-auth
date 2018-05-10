defmodule TdAuth.Repo.Migrations.AddDescriptionFieldToGroup do
  use Ecto.Migration

  def change do
    alter table(:groups) do
      add :description, :string
    end
  end
end
