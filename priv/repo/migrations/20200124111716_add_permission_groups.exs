defmodule TdAuth.Repo.Migrations.AddPermissionGroups do
  use Ecto.Migration
  import Ecto.Query
  
  alias TdAuth.Repo

  @groups ["taxonomy_membership", "taxonomy", "business_glossary", "data_dictionary", "data_quality", "ingests"]

  def change do
    @groups
    |> Enum.map(&with_permissions/1)
    |> Enum.each(&create_group/1)
  end

  defp with_permissions("taxonomy_membership" = group) do
    {group, query_by("%acl_entry%")}
  end

  defp with_permissions("taxonomy" = group) do
    {group, query_by("%domain%")}
  end

  defp with_permissions("business_glossary" = group) do
    {group, query_by("%business_concept%")}
  end

  defp with_permissions("data_dictionary" = group) do
    {group, query_by("%structure%")}
  end

  defp with_permissions("data_quality" = group) do
    {group, query_by("%quality_rule%")}
  end

  defp with_permissions("ingests" = group) do
    {group, query_by("%ingest%")}
  end

  defp query_by(pattern) do
    from(p in "permissions")
    |> where([p], like(p.name, ^pattern))
    |> select([p], %{id: p.id, name: p.name})
    |> Repo.all()
  end

  defp create_group({name, permissions}) do
    records = [[name: name, inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]]
    {_, [%{id: id}]} = Repo.insert_all("permission_groups", records, returning: [:id])
    permission_ids = Enum.map(permissions, & &1.id)
    
    from(p in "permissions")
    |> where([p], p.id in ^permission_ids)
    |> update(set: [permission_group_id: ^id])
    |> Repo.update_all([])
  end
end
