defmodule TdAuth.Repo.Migrations.UpdateExecutionPermissionName do
  use Ecto.Migration

  alias TdAuth.Repo

  import Ecto.Query

  def up do
    from(p in "permissions")
    |> where([p], p.name == "execute_quality_rule")
    |> update([_],
      set: [name: "execute_quality_rule_implementations", updated_at: ^DateTime.utc_now()]
    )
    |> Repo.update_all([])
  end

  def down do
    from(p in "permissions")
    |> where([p], p.name == "execute_quality_rule_implementations")
    |> update([_], set: [name: "execute_quality_rule", updated_at: ^DateTime.utc_now()])
    |> Repo.update_all([])
  end
end
