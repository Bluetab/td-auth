defmodule TdAuth.Repo.Migrations.AddManageQualityRuleImplementationPermission do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "manage_quality_rule_implementations"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end
end