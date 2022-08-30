defmodule TdAuth.Permissions.PermissionTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions.Constants
  alias TdAuth.Permissions.Permission

  @custom_prefix Constants.custom_prefix()

  describe "Permission.changeset_external/1" do
    test "casts valid parameters" do
      %{id: permission_group_id} = insert(:permission_group)

      params = %{
        "name" => "#{@custom_prefix}some_permission",
        "permission_group_id" => permission_group_id
      }

      assert %{
               valid?: true,
               changes: %{
                 name: "#{@custom_prefix}some_permission",
                 permission_group_id: ^permission_group_id
               }
             } = Permission.changeset_external(params)
    end

    test "invalid data returns errored changeset" do
      %{id: permission_group_id} = insert(:permission_group)

      params = %{
        "name" => "some_permission",
        "permission_group_id" => permission_group_id
      }

      assert %{
               valid?: false,
               errors: [
                 name:
                   {"External permission creation requires a name starting with '#{@custom_prefix}'",
                    []}
               ]
             } = Permission.changeset_external(params)
    end

    test "captures foreign key constraint on permission_group" do
      non_existent_permission_group_id = 12_345

      params = %{
        "name" => "some_permission",
        "permission_group_id" => non_existent_permission_group_id
      }

      assert {:error, %{errors: errors}} =
               params
               |> Permission.changeset()
               |> Repo.insert()

      assert {"does not exist",
              [
                {:constraint, :foreign},
                {:constraint_name, "permissions_permission_group_id_fkey"}
              ]} = errors[:permission_group_id]
    end
  end
end
