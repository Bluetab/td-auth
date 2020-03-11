defmodule TdAuth.Repo.Migrations.AddLineageDashboardPermissions do
  use Ecto.Migration
  import Ecto.Query

  alias TdAuth.Permissions
  alias TdAuth.Repo

  @permissions [dashboards: ["view_dashboard"], lineage: ["view_lineage"]]

  def change do
    @permissions
    |> Keyword.keys()
    |> Enum.map(&create_permissions/1)
    
  end

  defp create_permissions(group) do
    pg = permission_group(group)

    @permissions
    |> Keyword.get(group)
    |> Enum.each(&Permissions.create_permission(%{name: &1, permission_group_id: pg.id})) 
  end

  defp permission_group(group) do
    from(p in "permission_groups")
    |> select([:id])
    |> Repo.get_by(name: Atom.to_string(group))
  end
end
