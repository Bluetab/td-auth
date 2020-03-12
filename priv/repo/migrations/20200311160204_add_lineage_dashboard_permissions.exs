defmodule TdAuth.Repo.Migrations.AddLineageDashboardPermissions do
  use Ecto.Migration
  import Ecto.Query

  alias TdAuth.Repo

  @permissions [dashboards: ["view_dashboard"], lineage: ["view_lineage"]]

  def up do
    @permissions
    |> Keyword.keys()
    |> Enum.each(&create_permissions/1)
  end

  def down do
    @permissions
    |> Keyword.keys()
    |> Enum.each(&delete_permissions/1)
  end

  defp create_permissions(group) do
    pg = permission_group(group)

    @permissions
    |> Keyword.get(group)
    |> Enum.each(&insert_permission(%{name: &1, permission_group_id: pg.id})) 
  end

  defp permission_group(group) do
    from(p in "permission_groups")
    |> select([:id])
    |> Repo.get_by(name: Atom.to_string(group))
  end

  defp insert_permission(%{name: name, permission_group_id: permission_group_id}) do
    records = [[name: name, inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), permission_group_id: permission_group_id]]
    Repo.insert_all("permissions", records)
  end

  defp delete_permissions(group) do
    pg = permission_group(group)

    from(p in "permissions")
    |> where([p], p.permission_group_id == ^pg.id)
    |> Repo.delete_all()
  end
end
