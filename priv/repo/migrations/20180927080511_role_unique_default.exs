defmodule TdAuth.Repo.Migrations.RoleUniqueDefault do
  use Ecto.Migration

  def change do
    create(unique_index(:roles, [:is_default], where: "is_default is true"))
  end
end
