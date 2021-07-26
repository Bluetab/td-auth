defmodule TdAuth.Repo.Migrations.AddUniqueGroupName do
  use Ecto.Migration

  def change do
    create(unique_index(:groups, [:name]))
  end
end
