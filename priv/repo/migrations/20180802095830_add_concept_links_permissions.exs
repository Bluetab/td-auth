defmodule TdAuth.Repo.Migrations.AddConceptLinksPermissions do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "create_business_concept_link",
    "delete_business_concept_link"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end

end
