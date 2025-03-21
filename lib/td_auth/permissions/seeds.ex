defmodule TdAuth.Permissions.Seeds do
  @moduledoc """
  Task to load current permissions and permission groups on application startup.
  """

  use Task

  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Repo

  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)

  import Ecto.Query

  require Logger

  @permissions_by_group %{
    "business_glossary_view" => [
      "view_published_business_concepts",
      "view_versioned_business_concepts"
    ],
    "business_glossary_management" => [
      "create_business_concept",
      "delete_business_concept",
      "deprecate_business_concept",
      "manage_business_concept_links",
      "manage_confidential_business_concepts",
      "publish_business_concept",
      "reject_business_concept",
      "send_business_concept_for_approval",
      "update_business_concept",
      "view_approval_pending_business_concepts",
      "view_deprecated_business_concepts",
      "view_draft_business_concepts",
      "view_rejected_business_concepts",
      "share_with_domain",
      "manage_business_concepts_domain",
      "ai_business_concepts"
    ],
    "configurations" => [
      "manage_configurations"
    ],
    "dashboards" => [
      "view_dashboard"
    ],
    "data_dictionary" => [
      "create_data_structure",
      "delete_data_structure",
      "link_data_structure",
      "link_structure_to_structure",
      "manage_confidential_structures",
      "manage_structures_domain",
      "manage_structures_metadata",
      "update_data_structure",
      "view_data_structure",
      "view_data_structures_profile",
      "profile_structures",
      "view_structure_note",
      "view_structure_note_history",
      "link_data_structure_tag",
      "view_protected_metadata"
    ],
    "data_dictionary_structure_notes" => [
      "create_structure_note",
      "edit_structure_note",
      "send_structure_note_to_approval",
      "reject_structure_note",
      "unreject_structure_note",
      "deprecate_structure_note",
      "ai_structure_note",
      "publish_structure_note",
      "delete_structure_note",
      "publish_structure_note_from_draft"
    ],
    "quality" => [
      "view_quality_rule",
      "manage_quality_rule"
    ],
    "quality_control" => [
      ## view_quality_controls -> View published and versioned quality control and its scores.
      "view_quality_controls",
      # write_quality_controls -> View all quality controls but deprecated (with scores).
      # Create, edit, send for approval, send to draft.
      "write_quality_controls",
      # manage_quality_controls  -> View all quality controls and scores.
      # All write actions and publish, deprecate, change domain and activate and deactivate.
      "manage_quality_controls",
      # execute_quality_controls Create ScoresGroups.
      "execute_quality_controls",
      # manage_scores delete scores
      "manage_scores"
    ],
    "quality_implementation_workflow_management" => [
      # new, edit, submit for approval, delete (draft/rejected)
      "manage_basic_implementations",
      # new, edit, submit for approval, delete (draft/rejected),
      # clone -> only implementation with rule
      "manage_quality_rule_implementations",
      # new, edit, submit for approval, delete (draft/rejected),
      # clone -> only native implementation with rule
      "manage_raw_quality_rule_implementations",
      # manage impl/manage native: new, edit, submit for approval,
      # delete (draft/rejected), clone -> only impl/native with no rule
      "manage_ruleless_implementations",
      # Publish, Reject, deprecate implementations
      "publish_implementation"
    ],
    "quality_implementation_additional_actions" => [
      "execute_quality_rule_implementations",
      "manage_rule_results",
      "manage_remediations",
      "link_implementation_structure",
      "link_implementation_business_concept",
      "manage_segments"
    ],
    "data_sources" => [
      "manage_data_sources"
    ],
    "ingests" => [
      "create_ingest",
      "delete_ingest",
      "deprecate_ingest",
      "manage_ingest_relations",
      "publish_ingest",
      "reject_ingest",
      "send_ingest_for_approval",
      "update_ingest",
      "view_approval_pending_ingests",
      "view_deprecated_ingests",
      "view_draft_ingests",
      "view_published_ingests",
      "view_rejected_ingests",
      "view_versioned_ingests"
    ],
    "lineage" => [
      "view_lineage"
    ],
    "taxonomy" => [
      "create_domain",
      "delete_domain",
      "update_domain",
      "view_domain"
    ],
    "taxonomy_membership" => [
      "create_acl_entry",
      "delete_acl_entry",
      "update_acl_entry"
    ],
    "grants_visualization" => [
      "view_grants"
    ],
    "grants" => [
      "create_grant_request",
      "manage_grant_removal",
      "manage_foreign_grant_removal",
      "create_foreign_grant_request",
      "allow_foreign_grant_request"
    ],
    "grants_management" => [
      "manage_grants",
      "approve_grant_request"
    ],
    "structures_membership" => [
      "manage_structure_acl_entry"
    ]
  }

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    case Repo.transaction(fn -> seed_permissions() end) do
      {:ok, _} -> Logger.info("Permissions are current")
    end
  end

  def permissions do
    Enum.flat_map(@permissions_by_group, &elem(&1, 1))
  end

  def permission_groups do
    Map.keys(@permissions_by_group)
  end

  defp seed_permissions do
    ts = timestamp()
    insert_permissions(ts)
    insert_groups(ts)
    update_groups(ts)
    obsolete_permissions()
    obsolete_groups()
  end

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
  end

  defp obsolete_permissions do
    permission_names = permissions()

    Permission
    |> where([p], p.name not in ^permission_names and not like(p.name, ^"#{@custom_prefix}%"))
    |> select([p], p.name)
    |> Repo.delete_all()
    |> case do
      {0, _} -> :ok
      {count, names} -> Logger.warning("Deleted #{count} permissions: #{inspect(names)}")
    end
  end

  defp obsolete_groups do
    group_names = permission_groups()

    PermissionGroup
    |> where([g], g.name not in ^group_names and not like(g.name, ^"#{@custom_prefix}%"))
    |> select([g], g.name)
    |> Repo.delete_all()
    |> case do
      {0, _} -> :ok
      {count, names} -> Logger.warning("Deleted #{count} permission groups: #{inspect(names)}")
    end
  end

  defp insert_permissions(ts) do
    params =
      permissions()
      |> Enum.map(&[name: &1, inserted_at: ts, updated_at: ts])

    case Repo.insert_all(Permission, params,
           conflict_target: [:name],
           on_conflict: :nothing,
           returning: [:name]
         ) do
      {0, _} ->
        Logger.debug("Permissions are current")

      {count, perms} ->
        names = Enum.map(perms, & &1.name)
        Logger.info("Inserted #{count} permissions: #{inspect(names)}")
    end
  end

  defp insert_groups(ts) do
    params =
      permission_groups()
      |> Enum.map(&[name: &1, inserted_at: ts, updated_at: ts])

    case Repo.insert_all(PermissionGroup, params, on_conflict: :nothing, returning: [:name]) do
      {0, _} ->
        Logger.debug("Permission groups are current")

      {count, structs} ->
        names = Enum.map(structs, & &1.name)
        Logger.info("Upserted #{count} permission groups: #{inspect(names)}")
    end
  end

  defp update_groups(ts) do
    group_name_to_id = PermissionGroup |> Repo.all() |> Map.new(&{&1.name, &1.id})

    Enum.each(@permissions_by_group, fn {group_name, permission_names} ->
      group_id = Map.fetch!(group_name_to_id, group_name)

      queryable =
        Permission
        |> where([p], p.name in ^permission_names)
        |> where([p], is_nil(p.permission_group_id) or p.permission_group_id != ^group_id)
        |> select([p], p.name)

      case Repo.update_all(queryable, set: [permission_group_id: group_id, updated_at: ts]) do
        {0, _} -> Logger.debug("Permissions in group #{group_name} are current")
        {count, names} -> Logger.info("Updated #{count} permissions: #{inspect(names)}")
      end
    end)
  end
end
