defmodule TdAuth.Repo.Migrations.AddViewDataStructuresProfilePermission do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "view_data_structures_profile"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end
end
