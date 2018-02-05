defmodule TdAuth.Repo.Migrations.AddSuperuser do
  use Ecto.Migration

  alias TdAuth.Accounts

  @valid_attrs %{password: "mypass",
                 user_name: "app-admin"}

  def change do
    Accounts.create_user(@valid_attrs)
  end
end
