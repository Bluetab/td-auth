defmodule TdAuth.Permissions.RoleTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions.Constants
  alias TdAuth.Permissions.RolePermission
  alias TdAuth.Permissions.Roles

  @custom_prefix Constants.custom_prefix()

  setup do
    role = insert(:role, permissions: [build(:permission)])
    permissions = Enum.map(1..20, fn _ -> insert(:permission) end)
    [permissions: permissions, role: role]
  end

  describe "Roles.list_roles/0" do
    test "list_roles/0 returns all roles", %{role: %{id: role_id}} do
      assert [%{id: ^role_id}] = Roles.list_roles()
      insert(:role)
      assert [_, _] = Roles.list_roles()
    end
  end

  describe "Roles.get_role!/1" do
    test "returns the role with given id", %{role: expected} do
      role = Roles.get_role!(expected.id)
      assert_structs_equal(role, expected, [:id, :name, :inserted_at])
    end
  end

  describe "Roles.create_role/1" do
    test "with valid data creates a role" do
      %{name: name} = params_for(:role)
      assert {:ok, %{role: role}} = Roles.create_role(%{name: name})
      assert %{name: ^name} = role
    end

    test "replaces default role if is_default is true" do
      role1 = insert(:role, is_default: true, name: "old_default")

      assert {:ok, multi} = Roles.create_role(%{name: "new_default", is_default: true})
      assert %{role: role2, unset_default: {1, [prev_default]}} = multi
      assert %{name: "new_default", is_default: true} = role2
      assert %{is_default: false} = prev_default

      assert_structs_equal(role1, prev_default, [:id, :name, :inserted_at])
    end

    test "with invalid data returns error changeset" do
      assert {:error, :role, %Ecto.Changeset{}, %{}} = Roles.create_role(%{})
    end
  end

  describe "Roles.update_role/2" do
    test "with valid data updates the role" do
      role = insert(:role)

      assert {:ok, %{role: %{name: "updated role"}}} =
               Roles.update_role(role, %{name: "updated role"})
    end

    test "unsets current default role" do
      default = insert(:role, is_default: true)
      role = insert(:role)

      assert {:ok, %{role: updated, unset_default: {1, [prev_default]}}} =
               Roles.update_role(role, %{is_default: true})

      assert updated.is_default
      refute prev_default.is_default
      assert_structs_equal(role, updated, [:id, :name, :inserted_at])
      assert_structs_equal(prev_default, default, [:id, :name, :inserted_at])
    end

    test "with invalid data returns error changeset" do
      role = insert(:role)
      assert {:error, :role, %Ecto.Changeset{}, %{}} = Roles.update_role(role, %{name: nil})
    end
  end

  describe "Roles.get_by/1 " do
    test "returns the default role" do
      refute Roles.get_by(is_default: true)
      role = insert(:role, is_default: true)
      assert Roles.get_by(is_default: true) == role
    end

    test "returns a role by name" do
      refute Roles.get_by(name: "foo")
      role = insert(:role, name: "foo")
      assert Roles.get_by(name: "foo") == role
    end
  end

  describe "Roles.delete_role/1" do
    test "deletes the role" do
      %{id: role_id} = role = insert(:role)
      assert {:ok, %{role: role}} = Roles.delete_role(role)
      assert %{__meta__: %{state: :deleted}, id: ^role_id} = role
    end
  end

  describe "Roles.add_permission/2" do
    test "adds permission to a role", %{role: %{id: role_id}} do
      %{id: permission_id} = insert(:permission, name: "#{@custom_prefix}permission")

      assert {:ok, %RolePermission{role_id: ^role_id, permission_id: ^permission_id}} =
               Roles.add_permission(role_id, permission_id)
    end
  end

  describe "Roles.delete_permission/2" do
    test "deletes permission from a role", %{permissions: permissions} do
      %{id: role_id} = insert(:role, name: "role_with_permissions", permissions: permissions)
      [%{id: permission_id}] = Enum.take_random(permissions, 1)

      assert {:ok, %RolePermission{role_id: ^role_id, permission_id: ^permission_id}} =
               Roles.delete_permission(role_id, permission_id)
    end
  end

  describe "Roles.put_permissions/2" do
    test "replaces the permissions of a role", %{role: role, permissions: permissions} do
      role_permissions = Enum.take_random(permissions, 5)
      assert {:ok, %{role: role}} = Roles.put_permissions(role, role_permissions)
      assert_lists_equal(role.permissions, role_permissions)

      assert {:ok, %{role: role}} = Roles.put_permissions(role, [])
      assert role.permissions == []
    end
  end
end
