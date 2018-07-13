defmodule TdAuth.Repo.Migrations.AddApiAdmin do
  use Ecto.Migration

  alias TdAuth.Accounts

  @user_attrs %{password: "apipass",
                user_name: "api-admin",
                email: "truedat.api@bluetab.net",
                is_admin: true,
                is_protected: true}

  def change do
    Accounts.create_user_nocache(@user_attrs)
  end
end
