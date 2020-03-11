defmodule TdAuth.Repo.Migrations.AddLineageDashboardGroups do
  use Ecto.Migration
  alias TdAuth.Permissions
  
  @names ["dashboards", "lineage"]

  def change do
    @names
    |> Enum.each(&load_group/1)
  end

  defp load_group(name) do
    Permissions.create_permission_group(%{name: name})
  end
end
