defmodule TdAuth.Repo.Migrations.AddDataStructuresPermissions do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "update_data_structure",
    "view_data_structure"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end

end
