defmodule TdAuth.Repo.Migrations.UpdadeAppAdmin do
  use Ecto.Migration
  alias TdAuth.Accounts.User
  alias TdAuth.Repo

  @valid_attrs %{password: "mypass",
                 user_name: "app-admin",
                 email: "truedat@bluetab.net",
                 is_admin: true}

  def change do
    Repo.get_by(User, user_name: "app-admin")
    |> User.update_changeset(@valid_attrs)
    |> Repo.update()
  end
end
