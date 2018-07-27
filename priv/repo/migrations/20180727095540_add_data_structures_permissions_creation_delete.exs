defmodule TdAuth.Repo.Migrations.AddDataStructuresPermissionsCreationDelete do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "create_data_structure",
    "delete_data_structure"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end
end
