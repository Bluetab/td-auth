defmodule TdAuth.Repo.Migrations.AddLineageDashboardGroups do
  use Ecto.Migration
  import Ecto.Query

  alias TdAuth.Repo
  
  @names ["dashboards", "lineage"]

  def up do
    records = Enum.map(@names, &%{name: &1, inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()})
    Repo.insert_all("permission_groups", records)
  end

  def down do
    from(p in "permission_groups")
    |> where([p], p.name in ^@names)
    |> Repo.delete_all()      
  end
end
