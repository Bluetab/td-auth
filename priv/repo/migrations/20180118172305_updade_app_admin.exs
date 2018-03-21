defmodule TdAuth.Repo.Migrations.UpdadeAppAdmin do
  use Ecto.Migration
  alias TdAuth.Accounts

  @valid_attrs %{password: "mypass",
                 user_name: "app-admin",
                 email: "truedat@bluetab.net",
                 is_admin: true}

  def change do
    user = Accounts.get_user_by_name("app-admin")
    Accounts.update_user(user, @valid_attrs)
  end
end
