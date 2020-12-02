defmodule TdAuth.Repo.Migrations.SplitBgPermissionGroup do
  use Ecto.Migration

  import Ecto.Query, warn: false

  alias TdAuth.Repo

  def up do
    Repo.insert_all(
      "permission_groups",
      [
        %{
          name: "business_glossary_view",
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ]
    )

    from(p in "permission_groups")
    |> where([p], p.name == "business_glossary")
    |> update(set: [name: "business_glossary_management"])
    |> Repo.update_all([])
  end

  def down do
    from(p in "permission_groups")
    |> where([p], p.name == "business_glossary_view")
    |> Repo.delete_all([])

    from(p in "permission_groups")
    |> where([p], p.name == "business_glossary_management")
    |> update(set: [name: "business_glossary"])
    |> Repo.update_all([])
  end
end
