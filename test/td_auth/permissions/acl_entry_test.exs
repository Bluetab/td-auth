defmodule TdAuth.Permissions.AclEntryTest do
  use TdAuth.DataCase

  alias TdAuth.Accounts
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdCache.AclCache
  alias TdCache.Redix

  describe "acl_entries" do
    @update_attrs %{
      resource_id: 43,
      resource_type: "domain"
    }
    @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

    def acl_entry_fixture(role_name \\ "watch") do
      user = insert(:user)
      role = Role.role_get_or_create_by_name(role_name)

      insert(:acl_entry_resource, principal_id: user.id, resource_id: 1234, role: role)
    end

    def group_acl_entry_fixture(role_name \\ "watch") do
      group = build(:group)
      role = Role.role_get_or_create_by_name(role_name)

      insert(
        :acl_entry,
        principal_type: "group",
        principal_id: group.id,
        resource_type: "domain",
        resource_id: 1234,
        role: role
      )
    end

    defp get_comparable_acl_entry_fields(acl_entry) do
      Map.take(acl_entry, [
        "principal_id",
        "principal_type",
        "resource_id",
        "resource_type",
        "role_id"
      ])
    end

    test "cast/1 casts a map to an AclEntry struct" do
      attrs = %{
        "principal_id" => "1234",
        "principal_type" => "system",
        "resource_type" => "books",
        "role_id" => "32",
        "foo" => "bar"
      }

      assert AclEntry.cast(attrs) == %AclEntry{
               principal_id: 1234,
               principal_type: "system",
               resource_type: "books",
               role_id: 32
             }
    end

    test "list_acl_entries/0 returns all acl_entries" do
      acl_entry = acl_entry_fixture()
      acl_entry = get_comparable_acl_entry_fields(acl_entry)
      acl_entries = Enum.map(AclEntry.list_acl_entries(), &get_comparable_acl_entry_fields(&1))
      assert acl_entries == [acl_entry]
    end

    test "list_acl_entries_by_principal/1 returns all acl_entries filtered by principal" do
      user_permission_group = insert(:permission_group, name: "user_permission_group")
      group_permission_group = insert(:permission_group, name: "group_permission_group")

      create = insert(:permission, name: "create", permission_group: user_permission_group)
      view = insert(:permission, name: "view", permission_group: group_permission_group)

      owner = insert(:role, name: "owner", permissions: [create])
      viewer = insert(:role, name: "viewer", permissions: [view])

      principal = insert(:group)

      user =
        insert(:acl_entry,
          resource_id: 1,
          principal_id: principal.id + 1,
          principal_type: "user",
          resource_type: "domain",
          role: owner
        )

      group =
        insert(:acl_entry,
          resource_id: 1,
          principal_id: principal.id,
          principal_type: "group",
          resource_type: "domain",
          role: viewer
        )

      user_entries =
        AclEntry.list_acl_entries_by_principal(%{
          principal_id: user.principal_id,
          principal_type: user.principal_type
        })

      group_entries =
        AclEntry.list_acl_entries_by_principal(%{
          principal_id: group.principal_id,
          principal_type: group.principal_type
        })

      empty =
        AclEntry.list_acl_entries_by_principal(%{
          principal_id: user.principal_id,
          principal_type: "foo"
        })

      assert empty == []
      assert length(user_entries) == 1
      assert length(group_entries) == 1
      assert %AclEntry{principal_id: p_id, principal_type: p_type, role: role} = hd(user_entries)
      assert p_id == user.principal_id
      assert p_type == user.principal_type
      assert role == owner
      assert role.permissions == [create]
      assert Enum.map(role.permissions, & &1.permission_group) == [user_permission_group]

      assert %AclEntry{principal_id: p_id, principal_type: p_type, role: role} = hd(group_entries)
      assert p_id == group.principal_id
      assert p_type == group.principal_type
      assert role == viewer
      assert role.permissions == [view]
      assert Enum.map(role.permissions, & &1.permission_group) == [group_permission_group]
    end

    test "get_acl_entry!/1 returns the acl_entry with given id" do
      acl_entry = acl_entry_fixture()
      get_acl_entry = AclEntry.get_acl_entry!(acl_entry.id)

      assert get_comparable_acl_entry_fields(get_acl_entry) ==
               get_comparable_acl_entry_fields(acl_entry)
    end

    test "create_acl_entry/1 with valid data creates a acl_entry" do
      user = insert(:user)
      role = Role.role_get_or_create_by_name("watch")

      valid_attrs = %{
        principal_id: user.id,
        principal_type: "user",
        resource_id: 1234,
        resource_type: "domain",
        role_id: role.id
      }

      {:ok, acl_entry = %AclEntry{}} = AclEntry.create_acl_entry(valid_attrs)
      assert acl_entry.principal_id == user.id
      assert acl_entry.principal_type == "user"
      assert acl_entry.resource_id == 1234
      assert acl_entry.resource_type == "domain"
      assert acl_entry.role_id == role.id
    end

    test "create_acl_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AclEntry.create_acl_entry(@invalid_attrs)
    end

    test "update_acl_entry/2 with valid data updates the acl_entry" do
      acl_entry = acl_entry_fixture()
      assert {:ok, acl_entry} = AclEntry.update_acl_entry(acl_entry, @update_attrs)
      assert %AclEntry{} = acl_entry
      assert acl_entry.resource_id == 43
      assert acl_entry.resource_type == @update_attrs.resource_type
    end

    test "update_acl_entry/2 with invalid data returns error changeset" do
      acl_entry = acl_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = AclEntry.update_acl_entry(acl_entry, @invalid_attrs)
      repo_acl_entry = AclEntry.get_acl_entry!(acl_entry.id)
      assert acl_entry.id == repo_acl_entry.id
      assert acl_entry.principal_type == repo_acl_entry.principal_type
      assert acl_entry.resource_id == repo_acl_entry.resource_id
      assert acl_entry.resource_type == repo_acl_entry.resource_type
      assert acl_entry.role_id == repo_acl_entry.role_id
    end

    test "delete_acl_entry/1 deletes the acl_entry" do
      acl_entry = acl_entry_fixture()

      key =
        AclCache.create_acl_role_users_key(
          acl_entry.resource_id,
          acl_entry.resource_type,
          acl_entry.role.name
        )

      assert not Redix.exists?("#{key}")
      assert {:ok, %AclEntry{}} = AclEntry.delete_acl_entry(acl_entry)
      assert_raise Ecto.NoResultsError, fn -> AclEntry.get_acl_entry!(acl_entry.id) end
    end

    test "change_acl_entry/1 returns a acl_entry changeset" do
      acl_entry = acl_entry_fixture()
      assert %Ecto.Changeset{} = AclEntry.change_acl_entry(acl_entry)
    end

    test "list_user_roles/1 returns user roles for a specified resource" do
      group = insert(:group)

      {:ok, user} =
        insert(:user)
        |> Accounts.add_groups_to_user([group.name])

      acl_entry = group_acl_entry_fixture()
      role_name = acl_entry.role.name

      [{^role_name, users}] =
        AclEntry.list_user_roles(acl_entry.resource_type, acl_entry.resource_id)

      assert length(users) == 1
      assert Enum.at(users, 0).id == user.id
    end
  end
end
