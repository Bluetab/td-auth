defmodule TdAuth.Repo.Migrations.LoadPermissions do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "create_acl_entry",
    "update_acl_entry",
    "delete_acl_entry",
    "create_domain",
    "update_domain",
    "delete_domain",
    "view_domain",
    "create_business_concept",
    "update_business_concept",
    "send_business_concept_for_approval",
    "delete_business_concept",
    "publish_business_concept",
    "reject_business_concept",
    "deprecate_business_concept",
    "manage_business_concept_alias",
    "view_draft_business_concepts",
    "view_approval_pending_business_concepts",
    "view_published_business_concepts",
    "view_versioned_business_concepts",
    "view_rejected_business_concepts",
    "view_deprecated_business_concepts"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end

end
