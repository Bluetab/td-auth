defmodule TdAuth.Permissions.SeedsTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions

  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Permissions.Seeds

  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)

  test "run/1: obsolete_permissions and obsolete_groups do not delete custom permissions/groups" do
    permission_group = insert(:permission_group, name: "#{@custom_prefix}permission_group")
    insert(:permission, name: "#{@custom_prefix}permission", permission_group: permission_group)
    Seeds.run("ignored_argument")

    %Permission{name: "#{@custom_prefix}permission"} =
      Permissions.get_permission_by_name("#{@custom_prefix}permission")

    %PermissionGroup{name: "#{@custom_prefix}permission_group"} =
      Permissions.get_permission_group_by_name("#{@custom_prefix}permission_group")
  end
end
