defmodule TdAuth.Repo.Migrations.AddExecuteQualityRulePermission do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "execute_quality_rule"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end
end
