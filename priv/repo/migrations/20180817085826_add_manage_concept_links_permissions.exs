defmodule TdAuth.Repo.Migrations.AddManageConceptLinksPermissions do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "manage_business_concept_links"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end

end
