defmodule TdAuth.Repo.Migrations.RemoveDefaultUsers do
  use Ecto.Migration

  def up do
    execute("delete from users where user_name in ('app-admin', 'api-admin')")
  end

  def down, do: :ok
end
