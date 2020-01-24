defmodule TdAuth.PermissionsTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Permission

  describe "permissions" do
    test "list_permissions/0 returns all permissions" do
      current_permissions = Permission.permissions() |> Map.values() |> Enum.sort()

      stored_permissions =
        Permissions.list_permissions() |> Enum.map(&Map.get(&1, :name)) |> Enum.sort()

      assert current_permissions == stored_permissions
    end

    test "list_permissions/1 returns all permissions" do
      permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)
      permissions = Permissions.list_permissions([:permission_group])

      assert %Permission{permission_group: group} =
               Enum.find(permissions, fn %{id: id} -> id == permission.id end)

      assert group.id == permission_group.id
    end

    test "get_permission!/1 returns the premission with given id" do
      permission = List.first(Permissions.list_permissions())
      assert Permissions.get_permission!(permission.id) == permission
    end

    test "get_permission!/2 returns the premission and preloaded information with given id" do
      permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)
      assert Permissions.get_permission!(permission.id, [:permission_group]) == permission
      assert permission_group.id == permission.permission_group.id
    end
  end

  describe "permission_groups" do
    alias TdAuth.Permissions.PermissionGroup

    @valid_attrs %{name: "group name"}
    @update_attrs %{name: "new group name"}
    @groups ["taxonomy_membership", "taxonomy", "business_glossary", "data_dictionary", "data_quality", "ingests"]

    test "list_permission_groups/0 returns all permission_groups" do
      assert Enum.map(Permissions.list_permission_groups(), & &1.name) == @groups
    end

    test "list_permission_groups/1 returns all permission_groups with preloaded options" do
      permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)
      permission_groups = Permissions.list_permission_groups(permissions: :permission_group)

      assert Enum.find(permission_groups, & &1.id == permission_group.id).permissions == [permission]
    end

    test "get_permission_group!/1 returns the permission_group with given id" do
      permission_group = insert(:permission_group)
      assert Permissions.get_permission_group!(permission_group.id) == permission_group
    end

    test "get_permission_group!/2 returns the permission_group with given id and enriched options" do
      permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)

      assert %PermissionGroup{id: id, permissions: permissions} =
               Permissions.get_permission_group!(permission_group.id,
                 permissions: :permission_group
               )

      assert id == permission_group.id
      assert permissions == [permission]
    end

    test "get_permission_group!/2 raises Ecto.NoResultsError when group not found" do
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_permission_group!(1) end
    end

    test "create_permission_group/1 with valid data creates a permission_group" do
      assert {:ok, %PermissionGroup{} = permission_group} =
               Permissions.create_permission_group(@valid_attrs)
    end

    test "create_permission_group/1 with invalid data returns error changeset when name is duplicated" do
      permission_group = insert(:permission_group)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Permissions.create_permission_group(%{name: permission_group.name})

      name =
        errors
        |> Keyword.get(:name)
        |> elem(1)
        |> Keyword.get(:constraint_name)

      assert name == "permission_groups_name_index"
    end

    test "update_permission_group/2 with valid data updates the permission_group" do
      permission_group = insert(:permission_group)

      assert {:ok, %PermissionGroup{} = permission_group} =
               Permissions.update_permission_group(permission_group, @update_attrs)

      assert permission_group.name == @update_attrs.name
    end

    test "update_permission_group/2 with invalid data returns error changeset" do
      permission_group = insert(:permission_group)

      assert {:error, %Ecto.Changeset{}} =
               Permissions.update_permission_group(permission_group, %{name: nil})
    end

    test "delete_permission_group/1 deletes the permission_group" do
      permission_group = insert(:permission_group)
      assert {:ok, %PermissionGroup{}} = Permissions.delete_permission_group(permission_group)

      assert_raise Ecto.NoResultsError, fn ->
        Permissions.get_permission_group!(permission_group.id)
      end
    end

    test "delete_permission_group/1 returns an error when it has permissions" do
      permission_group = insert(:permission_group)
      insert(:permission, permission_group: permission_group)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Permissions.delete_permission_group(permission_group)

      key =
        errors
        |> Keyword.get(:permissions)
        |> elem(0)

      assert key == "group.delete.existing.permissions"
    end
  end
end
