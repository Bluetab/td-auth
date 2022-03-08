defmodule TdAuth.PermissionsTest do
  use TdAuth.DataCase

  alias TdAuth.CacheHelpers
  alias TdAuth.Permissions
  alias TdAuth.Permissions.PermissionGroup
  alias TdAuth.Repo

  @permission_keys [:id, :name, :permission_group_id]

  setup_all do
    domain_ids = 100_000..100_004
    domains = Enum.map(domain_ids, &build(:domain, id: &1))
    Enum.each(domains, &CacheHelpers.put_domain/1)

    [domains: domains]
  end

  describe "list_permissions/0" do
    test "returns all permissions" do
      permissions = Enum.map(1..5, fn _ -> insert(:permission) end)

      Permissions.list_permissions()
      |> assert_lists_equal(permissions, &assert_structs_equal(&1, &2, @permission_keys))
    end
  end

  describe "get_permission!/1" do
    test "returns the premission with given id" do
      %{id: id} = permission = insert(:permission)

      id
      |> Permissions.get_permission!()
      |> assert_structs_equal(permission, @permission_keys)
    end

    test "returns the premission and preloaded information with given id" do
      permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)
      assert Permissions.get_permission!(permission.id) == permission
      assert permission_group.id == permission.permission_group.id
    end
  end

  describe "list_permission_groups/1" do
    test "returns all permission_groups with preloaded options" do
      permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)

      permission_groups =
        Permissions.list_permission_groups()
        |> Repo.preload(permissions: :permission_group)

      assert Enum.find(permission_groups, &(&1.id == permission_group.id)).permissions == [
               permission
             ]
    end
  end

  describe "get_permission_group!/1" do
    test "returns the permission_group with given id" do
      permission_group = insert(:permission_group)
      assert Permissions.get_permission_group!(permission_group.id) == permission_group
    end

    test "returns the permission_group with given id and enriched options" do
      %{id: id} = permission_group = insert(:permission_group)
      permission = insert(:permission, permission_group: permission_group)

      assert %PermissionGroup{id: ^id, permissions: permissions} =
               id
               |> Permissions.get_permission_group!()
               |> Repo.preload(permissions: :permission_group)

      assert permissions == [permission]
    end

    test "raises Ecto.NoResultsError when group not found" do
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_permission_group!(-1) end
    end
  end

  describe "create_permission_group/1" do
    test "with valid data creates a permission_group" do
      assert {:ok, %PermissionGroup{} = _permission_group} =
               Permissions.create_permission_group(%{name: "name"})
    end

    test "with invalid data returns error changeset when name is duplicated" do
      %{name: name} = insert(:permission_group)

      assert {:error, %{errors: errors}} = Permissions.create_permission_group(%{name: name})

      assert {_, [constraint: :unique, constraint_name: "permission_groups_name_index"]} =
               errors[:name]
    end
  end

  describe "update_permission_group/2" do
    test "with valid data updates the permission_group" do
      permission_group = insert(:permission_group)

      %{name: name} = params = params_for(:permission_group)

      assert {:ok, %{name: ^name}} = Permissions.update_permission_group(permission_group, params)
    end

    test "with invalid data returns error changeset" do
      permission_group = insert(:permission_group)

      assert {:error, %Ecto.Changeset{}} =
               Permissions.update_permission_group(permission_group, %{name: nil})
    end
  end

  describe "delete_permission_group/1" do
    test "deletes the permission_group" do
      permission_group = insert(:permission_group)
      assert {:ok, %PermissionGroup{}} = Permissions.delete_permission_group(permission_group)

      assert_raise Ecto.NoResultsError, fn ->
        Permissions.get_permission_group!(permission_group.id)
      end
    end

    test "returns an error when it has permissions" do
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

  describe "default_permissions/0" do
    test "returns the names of the permissions of the default role" do
      assert Permissions.default_permissions() == []

      permissions = Enum.map(1..5, fn _ -> build(:permission) end)
      insert(:role, is_default: true, permissions: permissions)

      permission_names = Permissions.default_permissions()
      assert_lists_equal(permissions, permission_names, &(&1.name == &2))
    end
  end
end
