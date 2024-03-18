defmodule TdAuth.Permissions.PermissionGroupTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions.PermissionGroup

  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)

  describe "PermissionGroup.changeset_external/1" do
    test "casts valid parameters" do
      params = %{
        "name" => "#{@custom_prefix}some_permission_group"
      }

      assert %{
               valid?: true,
               changes: %{
                 name: "#{@custom_prefix}some_permission_group"
               }
             } = PermissionGroup.changeset_external(params)
    end

    test "invalid data returns errored changeset" do
      params = %{
        "name" => "some_permission_group"
      }

      assert %{
               valid?: false,
               errors: [
                 name:
                   {"External permission group creation requires a name starting with '#{@custom_prefix}'",
                    []}
               ]
             } = PermissionGroup.changeset_external(params)
    end
  end
end
