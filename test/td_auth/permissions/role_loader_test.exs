defmodule TdAuth.Permissions.RoleLoaderTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions.RoleLoader
  alias TdCache.Permissions
  alias TdCache.UserCache

  describe "RoleLoader" do
    test "server starts and " do
      assert {:ok, _pid} = start_supervised(RoleLoader)
    end

    test "put_permission_roles/0 updates cache" do
      %{permissions: [p1, p2]} =
        insert(:role, name: "role1", permissions: [build(:permission), build(:permission)])

      %{permissions: [_, p3]} =
        insert(:role, name: "role2", permissions: [p2, build(:permission)])

      assert {:ok, _} = RoleLoader.put_permission_roles()
      assert {:ok, ["role1"]} = Permissions.get_permission_roles(p1.name)
      assert {:ok, ["role2"]} = Permissions.get_permission_roles(p3.name)
      assert {:ok, [_, _]} = Permissions.get_permission_roles(p2.name)
      assert {:ok, []} = Permissions.get_permission_roles("foo")
    end

    test "put_permission_roles/0 without roles no updates cache" do
      %{permissions: []} = insert(:role, name: "role1", permissions: [])
      assert {:ok, nil} = RoleLoader.put_permission_roles()
    end

    test "reload_roles/1 updates all acl entries in cache" do
      %{id: user_id} = insert(:user)

      %{role: %{name: role_name}, resource_id: resource_id} =
        insert(:acl_entry, resource_type: "domain", user_id: user_id, group_id: nil)

      %{role: %{name: role_name_2}, resource_id: resource_id_2} =
        insert(:acl_entry, resource_type: "domain", user_id: user_id, group_id: nil)

      %{role: %{name: structure_role_name}, resource_id: structure_resource_id} =
        insert(:acl_entry, resource_type: "structure", user_id: user_id, group_id: nil)

      resources = RoleLoader.put_roles(reload_roles: true)
      assert length(resources) == 3

      assert UserCache.get_roles(user_id) ==
               {:ok, %{role_name => [resource_id], role_name_2 => [resource_id_2]}}

      assert UserCache.get_roles(user_id, "structure") ==
               {:ok, %{structure_role_name => [structure_resource_id]}}

      assert %{id: group_id, users: [%{id: user_id}, %{id: user_id2}]} =
               insert(:group, users: [build(:user), build(:user)])

      %{role: %{name: role_name}, resource_id: resource_id} =
        insert(:acl_entry, group_id: group_id, user_id: nil)

      new_resources = RoleLoader.put_roles(reload_roles: true)
      assert length(new_resources) == 5

      assert UserCache.get_roles(user_id) == {:ok, %{role_name => [resource_id]}}
      assert UserCache.get_roles(user_id2) == {:ok, %{role_name => [resource_id]}}
    end

    test "put_default_permissions/1 updates default permissions in cache" do
      permissions = Enum.map(1..10, fn _ -> build(:permission) end)
      default_permissions = Enum.take_random(permissions, 5)

      insert(:role, is_default: true, permissions: default_permissions)

      assert {:ok, [_, 5]} = RoleLoader.put_default_permissions()
    end
  end
end
