defmodule TdAuth.Permissions.RolePermissionTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions.RolePermission

  describe "Permission.changeset_external/1" do
    test "casts valid parameters" do
      %{id: role_id} = insert(:role)
      %{id: permission_id} = insert(:permission)
      params = %{role_id: role_id, permission_id: permission_id}

      assert %{
               valid?: true,
               changes: %{
                 role_id: ^role_id,
                 permission_id: ^permission_id
               }
             } = RolePermission.changeset(params)
    end

    test "invalid data returns errored changeset" do
      params = %{role_id: "not_a_numner", permission_id: "not_a_numner"}

      assert %{
               valid?: false,
               errors: [
                 {:role_id, {"is invalid", [{:type, :id}, {:validation, :cast}]}},
                 {:permission_id, {"is invalid", [type: :id, validation: :cast]}}
               ]
             } = RolePermission.changeset(params)
    end

    test "captures foreign key constraint on role" do
      non_existent_role_id = 12_345
      non_existent_permission_id = 12_345

      params = %{
        role_id: non_existent_role_id,
        permission_id: non_existent_permission_id
      }

      assert {:error, %{errors: errors}} =
               params
               |> RolePermission.changeset()
               |> Repo.insert()

      assert {"does not exist",
              [constraint: :foreign, constraint_name: "roles_permissions_role_id_fkey"]} =
               errors[:role_id]
    end

    test "captures foreign key constraint on permission" do
      %{id: role_id} = insert(:role)
      non_existent_permission_id = 12_345

      params = %{
        role_id: role_id,
        permission_id: non_existent_permission_id
      }

      assert {:error, %{errors: errors}} =
               params
               |> RolePermission.changeset()
               |> Repo.insert()

      assert {"does not exist",
              [constraint: :foreign, constraint_name: "roles_permissions_permission_id_fkey"]} =
               errors[:permission_id]
    end
  end
end
