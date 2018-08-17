defmodule TdAuth.Repo.Migrations.DeleteConceptLinksPermissions do
  use Ecto.Migration

  import Ecto.Query
  alias TdAuth.Repo
  alias TdAuth.Permissions.Permission

  @permissions [
    "create_business_concept_link",
    "delete_business_concept_link"
  ]

  def change do
    @permissions
      |> Enum.each(&delete_permission/1)
  end

  defp delete_permission(name) do
    from(p in Permission, where: p.name == ^name) |> Repo.delete_all
  end

end
