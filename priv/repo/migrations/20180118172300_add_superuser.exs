defmodule TdAuth.Repo.Migrations.AddSuperuser do
  use Ecto.Migration

  alias TdAuth.Accounts

  @valid_attrs %{password: "mypass",
                 user_name: "app-admin",
                 full_name: "App Admin",
                 email: "truedat@bluetab.net"}

  def change do
    Accounts.create_user_nocache(@valid_attrs)
  end
end
