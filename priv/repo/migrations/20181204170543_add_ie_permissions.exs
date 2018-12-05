defmodule TdAuth.Repo.Migrations.AddIePermissions do
  use Ecto.Migration

  alias TdAuth.Permissions

  @permissions [
    "create_ingest",
    "update_ingest",
    "send_ingest_for_approval",
    "delete_ingest",
    "publish_ingest",
    "reject_ingest",
    "deprecate_ingest",
    "view_draft_ingests",
    "view_approval_pending_ingests",
    "view_published_ingests",
    "view_versioned_ingests",
    "view_rejected_ingests",
    "view_deprecated_ingests"
  ]

  def change do
    @permissions
      |> Enum.each(&load_permission/1)
  end

  defp load_permission(name) do
    Permissions.create_permission(%{name: name})
  end
end
