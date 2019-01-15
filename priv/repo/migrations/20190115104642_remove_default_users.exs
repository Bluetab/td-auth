defmodule TdAuth.Repo.Migrations.RemoveDefaultUsers do
  use Ecto.Migration

  alias TdAuth.Accounts

  def change do
    remove_user("app-admin")
    remove_user("api-admin")
  end

  defp remove_user(username) do
    case Accounts.get_user_by_name(username) do
      nil -> nil
      user -> Accounts.delete_user_nocache(user)
    end
  end
end
