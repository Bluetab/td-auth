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
    "view_draft_ingest",
    "view_approval_pending_ingest",
    "view_published_ingest",
    "view_versioned_ingest",
    "view_rejected_ingest",
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
