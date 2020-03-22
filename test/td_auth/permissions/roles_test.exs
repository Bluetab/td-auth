defmodule TdAuth.Permissions.RoleTest do
  use TdAuth.DataCase

  import Ecto.Query

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Role
  alias TdAuth.Permissions.Roles

  describe "roles" do
    test "list_roles/0 returns all roles" do
      assert Enum.empty?(Roles.list_roles())
      %{id: role_id} = insert(:role)
      assert [%{id: ^role_id}] = Roles.list_roles()
    end

    test "get_role!/1 returns the role with given id" do
      role = insert(:role)
      assert Roles.get_role!(role.id) == role
    end

    test "create_role/1 with valid data creates a role" do
      assert {:ok, %{role: %Role{name: "valid role"}}} = Roles.create_role(%{name: "valid role"})
    end

    test "create_role/1 replaces default role if is_default is true" do
      role = insert(:role, is_default: true)

      assert {:ok,
              %{
                role: %Role{name: "default role", is_default: true},
                unset_default: {1, [prev_default]}
              }} = Roles.create_role(%{name: "default role", is_default: true})

      assert_structs_equal(role, prev_default, [:id, :name, :inserted_at])
      refute prev_default.is_default
    end

    test "create_role/1 with invalid data returns error changeset" do
      assert {:error, :role, %Ecto.Changeset{}, %{}} = Roles.create_role(%{})
    end

    test "update_role/2 with valid data updates the role" do
      role = insert(:role)

      assert {:ok, %{role: %{name: "updated role"}}} =
               Roles.update_role(role, %{name: "updated role"})
    end

    test "update_role/2 unsets current default role" do
      default = insert(:role, is_default: true)
      role = insert(:role)

      assert {:ok, %{role: updated, unset_default: {1, [prev_default]}}} =
               Roles.update_role(role, %{is_default: true})

      assert updated.is_default
      refute prev_default.is_default
      assert_structs_equal(role, updated, [:id, :name, :inserted_at])
      assert_structs_equal(prev_default, default, [:id, :name, :inserted_at])
    end

    test "update_role/2 with invalid data returns error changeset" do
      role = insert(:role)
      assert {:error, :role, %Ecto.Changeset{}, %{}} = Roles.update_role(role, %{name: nil})
    end

    test "get_default_role/0 returns the default role" do
      assert nil == Roles.get_default_role()
      role = insert(:role, is_default: true)
      assert Roles.get_default_role() == role
    end

    test "delete_role/1 deletes the role" do
      %{id: role_id} = role = insert(:role)
      assert {:ok, %Role{}} = Roles.delete_role(role)
      refute Repo.exists?(from(r in Role, where: [id: ^role_id]))
    end
  end

  describe "role permissions" do
    @role_attrs %{name: "rolename"}

    test "put_permissions/2 adds permissions to a role" do
      Roles.create_role(@role_attrs)

      permissions = Permissions.list_permissions()
      permissions = Enum.sort(permissions, &(&1.name < &2.name))

      role = Roles.role_get_or_create_by_name(@role_attrs.name)
      Roles.put_permissions(role, permissions)

      role = Roles.role_get_or_create_by_name(@role_attrs.name)
      stored_permissions = Roles.get_role_permissions(role)
      stored_permissions = Enum.sort(stored_permissions, &(&1.name < &2.name))

      assert permissions == stored_permissions
    end

    test "put_permissions/2 delete all permissions" do
      Roles.create_role(@role_attrs)

      permissions = Permissions.list_permissions()
      permissions = Enum.sort(permissions, &(&1.name < &2.name))

      role = Roles.role_get_or_create_by_name(@role_attrs.name)
      Roles.put_permissions(role, permissions)

      role = Roles.role_get_or_create_by_name(@role_attrs.name)
      stored_permissions = Roles.get_role_permissions(role)
      stored_permissions = Enum.sort(stored_permissions, &(&1.name < &2.name))

      assert permissions == stored_permissions

      role = Roles.role_get_or_create_by_name(@role_attrs.name)
      Roles.put_permissions(role, [])

      role = Roles.role_get_or_create_by_name(@role_attrs.name)
      stored_permissions = Roles.get_role_permissions(role)

      assert [] == stored_permissions
    end
  end
end
