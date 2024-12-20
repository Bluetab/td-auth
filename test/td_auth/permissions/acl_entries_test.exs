defmodule TdAuth.Permissions.AclEntriesTest do
  use TdAuth.DataCase

  import TdAuth.TestOperators

  alias Ecto.Changeset
  alias TdAuth.CacheHelpers
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.RoleLoader
  alias TdCache.AclCache
  alias TdCache.UserCache

  @acl_entry_keys [
    :id,
    :description,
    :group_id,
    :resource_id,
    :resource_type,
    :role_id,
    :user_id
  ]

  setup_all do
    start_supervised!(TdAuth.Permissions.RoleLoader)
    :ok
  end

  describe "get_acl_entry!/1" do
    test "get_acl_entry!/1 returns the acl_entry with given id" do
      %{id: id} = insert(:acl_entry, resource_type: "foo", resource_id: 1)
      assert %{id: ^id} = AclEntries.get_acl_entry!(id)
    end
  end

  describe "list_acl_entries" do
    test "list_acl_entries/0 returns a list of acl entries" do
      %{id: id1} = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      %{id: id2} = insert(:acl_entry, resource_type: "bar", resource_id: 2)

      assert [%{id: ^id1}, %{id: ^id2}] = AclEntries.list_acl_entries()
    end

    test "list_acl_entries/1 returns a list of acl entries for a specified resource" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      _e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99)
      e3 = insert(:acl_entry, resource_type: "foo", resource_id: 12)

      result = AclEntries.list_acl_entries(%{resource_type: "foo", resource_id: 12})
      assert_lists_equal(result, [e1, e3], &assert_structs_equal(&1, &2, @acl_entry_keys))
    end

    test "list_acl_entries/1 returns a list of acl entries updated since a given timestamp" do
      %{updated_at: last_updated} = insert(:acl_entry)
      %{id: id} = insert(:acl_entry)

      assert [_, _] = AclEntries.list_acl_entries(%{updated_since: nil})
      assert [%{id: ^id}] = AclEntries.list_acl_entries(%{updated_since: last_updated})
    end

    test "list_acl_entries/1 returns a list of all acl entries for a user" do
      %{id: group_id, users: [%{id: user_id}]} = insert(:group, users: [build(:user)])

      e1 = insert(:acl_entry, user_id: user_id, group_id: nil)
      e2 = insert(:acl_entry, user_id: nil, group_id: group_id)
      _another = insert(:acl_entry)

      result = AclEntries.list_acl_entries(%{all_for_user: user_id})
      assert result ||| [e1, e2]
    end
  end

  describe "create_acl_entry/1" do
    test "with valid params creates an ACL entry and refreshes cache" do
      %{id: user_id} = user = insert(:user)
      %{id: role_id, name: role_name} = insert(:role)
      %{id: role_id_2, name: role_name_2} = insert(:role)
      CacheHelpers.put_user(user)

      %{resource_id: resource_id} =
        params = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: "domain",
          role_id: role_id,
          user_id: user_id
        }

      %{resource_id: resource_id_2} =
        params_2 = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: "domain",
          role_id: role_id_2,
          user_id: user_id
        }

      assert {:ok, acl_entry = %AclEntry{}} = AclEntries.create_acl_entry(params)
      assert {:ok, %AclEntry{}} = AclEntries.create_acl_entry(params_2)

      assert_changed(acl_entry, params)

      assert user_id in AclCache.get_acl_role_users("domain", resource_id, role_name)
      assert user_id in AclCache.get_acl_role_users("domain", resource_id_2, role_name_2)

      assert role_name in AclCache.get_acl_roles("domain", resource_id)
      assert role_name_2 in AclCache.get_acl_roles("domain", resource_id_2)
    end

    test "create ACL entry same role diferent domain" do
      %{id: user_id} = user = insert(:user)
      %{id: role_id, name: role_name} = insert(:role, name: "foo")

      CacheHelpers.put_user(user)

      %{resource_id: resource_id} =
        params = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: "domain",
          role_id: role_id,
          user_id: user_id
        }

      %{resource_id: resource_id_2} =
        params_2 = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: "domain",
          role_id: role_id,
          user_id: user_id
        }

      assert {:ok, %AclEntry{}} = AclEntries.create_acl_entry(params)

      assert {:ok, %AclEntry{}} = AclEntries.create_acl_entry(params_2)

      assert {:ok, %{^role_name => resource_ids}} = UserCache.get_roles(user_id, "domain")

      assert resource_ids ||| [resource_id, resource_id_2]
    end

    test "create ACL entry group with same role diferent domain" do
      %{id: user_id} = user = insert(:user)
      %{id: role_id, name: role_name} = insert(:role, name: "foo")

      %{id: group_id} = group = insert(:group, users: [user])

      CacheHelpers.put_user(user)
      CacheHelpers.put_group(group)

      %{resource_id: resource_id} =
        acl_params = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: "domain",
          role_id: role_id,
          group_id: group_id
        }

      %{resource_id: resource_id2} =
        acl_group_params = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: "domain",
          role_id: role_id,
          group_id: group_id
        }

      assert {:ok, _} = AclEntries.create_acl_entry(acl_params)
      assert {:ok, _} = AclEntries.create_acl_entry(acl_group_params)

      assert {:ok, %{^role_name => resource_ids}} = UserCache.get_roles(user_id, "domain")

      assert resource_ids ||| [resource_id, resource_id2]
    end

    test "with valid params for structure resource_type creates an ACL entry and refreshes cache" do
      %{id: user_id} = user = insert(:user)
      %{id: group_id} = group = insert(:group, users: [user])
      %{id: role_id, name: role_name} = insert(:role)
      CacheHelpers.put_user(user)
      CacheHelpers.put_group(group)
      resource_type = "structure"

      %{resource_id: resource_id} =
        acl_group_params = %{
          resource_id: System.unique_integer([:positive]),
          resource_type: resource_type,
          role_id: role_id,
          group_id: group_id
        }

      assert {:ok, group_acl_entry = %AclEntry{}} = AclEntries.create_acl_entry(acl_group_params)
      assert_changed(group_acl_entry, acl_group_params)
      assert user_id in AclCache.get_acl_role_users(resource_type, resource_id, role_name)
      assert role_name in AclCache.get_acl_roles(resource_type, resource_id)
      assert group_id in AclCache.get_acl_role_groups(resource_type, resource_id, role_name)
      assert role_name in AclCache.get_acl_group_roles(resource_type, resource_id)
    end

    test "enforces unique constraint on user_id and resource" do
      assert {:error, %Changeset{errors: errors}} =
               :acl_entry
               |> insert(principal_type: :user)
               |> Map.take([:user_id, :resource_type, :resource_id, :role_id])
               |> AclEntries.create_acl_entry()

      assert {_, [constraint: :unique, constraint_name: _]} = errors[:user_id]
    end

    test " enforces unique constraint on group_id and resource" do
      assert {:error, changeset = %Changeset{errors: errors}} =
               :acl_entry
               |> insert(principal_type: :group)
               |> Map.take([:group_id, :resource_type, :resource_id, :role_id])
               |> AclEntries.create_acl_entry()

      refute changeset.valid?
      assert {_, [constraint: :unique, constraint_name: _]} = errors[:group_id]
    end

    test "enforces foreign key constraint on user_id" do
      assert %{id: role_id} = insert(:role)

      assert {:error, changeset = %Changeset{errors: errors}} =
               %{
                 user_id: -1,
                 resource_type: "domain",
                 resource_id: 1234,
                 role_id: role_id
               }
               |> AclEntries.create_acl_entry()

      refute changeset.valid?
      assert {_, [constraint: :foreign, constraint_name: _]} = errors[:user_id]
    end

    test "enforces foreign key constraint on group_id" do
      assert %{id: role_id} = insert(:role)

      assert {:error, changeset = %Changeset{errors: errors}} =
               %{
                 group_id: -1,
                 resource_type: "domain",
                 resource_id: 1234,
                 role_id: role_id
               }
               |> AclEntries.create_acl_entry()

      refute changeset.valid?
      assert {_, [constraint: :foreign, constraint_name: _]} = errors[:group_id]
    end

    test "enforces foreign key constraint on role_id" do
      assert %{id: group_id} = insert(:group)

      assert {:error, changeset = %Changeset{errors: errors}} =
               %{
                 group_id: group_id,
                 resource_type: "domain",
                 resource_id: 1234,
                 role_id: -1
               }
               |> AclEntries.create_acl_entry()

      refute changeset.valid?
      assert {_, [constraint: :foreign, constraint_name: _]} = errors[:role_id]
    end

    test "enforces check constraint on user_id and group_id" do
      assert %{id: group_id} = insert(:group)
      assert %{id: user_id} = insert(:user)
      assert %{id: role_id} = insert(:role)

      assert {:error, changeset = %Changeset{errors: errors}} =
               %{
                 group_id: group_id,
                 resource_type: "domain",
                 resource_id: 1234,
                 role_id: role_id,
                 user_id: user_id
               }
               |> AclEntries.create_acl_entry()

      refute changeset.valid?
      assert {_, [constraint: :check, constraint_name: "user_xor_group"]} = errors[:group_id]
    end
  end

  describe "delete_acl_entry/1" do
    test " deletes the ACL Entry" do
      acl_entry = insert(:acl_entry)
      assert {:ok, %AclEntry{}} = AclEntries.delete_acl_entry(acl_entry)
    end

    test "deletes the ACL Entry and refresh cache" do
      role = insert(:role, name: "foo")
      role2 = insert(:role, name: "bar")
      %{id: user_id} = user = insert(:user)
      CacheHelpers.put_user(user)

      %{resource_id: resource_id, role: %{name: role_name}} =
        acl_entry = insert(:acl_entry, user_id: user_id, resource_type: "domain", role: role)

      %{resource_id: resource_id2, role: %{name: role_name2}} =
        acl_entry2 = insert(:acl_entry, user_id: user_id, resource_type: "domain", role: role2)

      RoleLoader.refresh_acl_roles(acl_entry)
      RoleLoader.refresh_acl_roles(acl_entry2)

      assert {:ok, %{^role_name => [^resource_id], ^role_name2 => [^resource_id2]}} =
               UserCache.get_roles(user_id, "domain")

      assert {:ok, %AclEntry{}} = AclEntries.delete_acl_entry(acl_entry)

      UserCache.get_roles(user_id, "domain")

      assert {:ok, %{role_name2 => [resource_id2]}} == UserCache.get_roles(user_id, "domain")
    end

    test "delete group ACL Entry and refresh cache for all members" do
      role = insert(:role, name: "foo")
      role2 = insert(:role, name: "bar")
      %{id: user_id} = user = insert(:user)
      %{id: user_id2} = user_2 = insert(:user)

      %{id: group_id} = group = insert(:group, users: [user, user_2])
      CacheHelpers.put_user(user)
      CacheHelpers.put_user(user_2)
      CacheHelpers.put_group(group)

      %{resource_id: resource_id, role: %{name: role_name}} =
        acl_entry = insert(:acl_entry, group_id: group_id, resource_type: "domain", role: role)

      %{id: id2, resource_id: resource_id2, role: %{name: role_name2}} =
        acl_entry2 = insert(:acl_entry, user_id: user_id, resource_type: "domain", role: role2)

      RoleLoader.refresh_acl_roles(acl_entry)

      RoleLoader.refresh_acl_roles(acl_entry2)

      assert {:ok, %{^role_name => [^resource_id], ^role_name2 => [^resource_id2]}} =
               UserCache.get_roles(user_id, "domain")

      assert {:ok, %AclEntry{}} = AclEntries.delete_acl_entry(acl_entry)

      assert {:ok, %{^role_name2 => [^resource_id2]}} = UserCache.get_roles(user_id, "domain")
      assert {:ok, nil} = UserCache.get_roles(user_id2, "domain")
      assert [%{id: ^id2}] = AclEntries.list_acl_entries()
    end

    test " applies filters" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99)
      e3 = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      e4 = insert(:acl_entry, resource_type: "foo", resource_id: 20)

      assert {2, entries} =
               AclEntries.delete_acl_entries(
                 resource_type: "foo",
                 resource_id: {:not_in, [99, 20]}
               )

      assert_lists_equal(entries, [e1, e3], &assert_structs_equal(&1, &2, @acl_entry_keys))

      assert {2, entries} =
               AclEntries.delete_acl_entries(resource_type: "foo", resource_id: {:in, [99, 20]})

      assert_lists_equal(entries, [e2, e4], &assert_structs_equal(&1, &2, @acl_entry_keys))
    end
  end

  describe "TdAuth.Permissions.AclEntries" do
    test "get_user_ids_by_resource_and_role/0 returns user_ids grouped by resource and role" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12, principal_type: :user)
      e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99, principal_type: :user)
      e3 = insert(:acl_entry, resource_type: "bar", resource_id: 12, principal_type: :user)
      e4 = insert(:acl_entry, resource_type: "bar", resource_id: 99, principal_type: :group)

      result = AclEntries.get_user_ids_by_resource_and_role()
      assert e1.user_id in Map.get(result, {e1.resource_type, e1.resource_id, e1.role.name}, [])
      assert e2.user_id in Map.get(result, {e2.resource_type, e2.resource_id, e2.role.name}, [])
      assert e3.user_id in Map.get(result, {e3.resource_type, e3.resource_id, e3.role.name}, [])

      assert Enum.all?(e4.group.users, fn u ->
               assert u.id in Map.get(
                        result,
                        {e4.resource_type, e4.resource_id, e4.role.name},
                        []
                      )
             end)
    end

    test "get_user_ids_by_resource_and_role/1 filters by resource_type and resource_id" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12, principal_type: :user)
      e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99, principal_type: :user)
      e3 = insert(:acl_entry, resource_type: "bar", resource_id: 12, principal_type: :user)
      e4 = insert(:acl_entry, resource_type: "bar", resource_id: 99, principal_type: :group)

      result =
        AclEntries.get_user_ids_by_resource_and_role(resource_type: "foo", resource_id: 12)
        |> Map.keys()

      assert {e1.resource_type, e1.resource_id, e1.role.name} in result
      refute {e2.resource_type, e2.resource_id, e2.role.name} in result
      refute {e3.resource_type, e3.resource_id, e3.role.name} in result
      refute {e4.resource_type, e4.resource_id, e4.role.name} in result
    end

    test "get_group_ids_by_resource_and_role/0 returns group_ids grouped by resource and role" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12, principal_type: :group)
      e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99, principal_type: :group)
      e3 = insert(:acl_entry, resource_type: "bar", resource_id: 12, principal_type: :group)

      result = AclEntries.get_group_ids_by_resource_and_role()
      assert e1.group_id in Map.get(result, {e1.resource_type, e1.resource_id, e1.role.name}, [])
      assert e2.group_id in Map.get(result, {e2.resource_type, e2.resource_id, e2.role.name}, [])
      assert e3.group_id in Map.get(result, {e3.resource_type, e3.resource_id, e3.role.name}, [])
    end

    test "get_group_ids_by_resource_and_role/1 filters by resource_type and resource_id" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12, principal_type: :group)
      e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99, principal_type: :group)

      result =
        AclEntries.get_group_ids_by_resource_and_role(resource_type: "foo", resource_id: 12)
        |> Map.keys()

      assert {e1.resource_type, e1.resource_id, e1.role.name} in result
      refute {e2.resource_type, e2.resource_id, e2.role.name} in result
    end

    test "find_by_resource_and_principal/1 applies filters" do
      insert(:acl_entry, resource_type: "foo", resource_id: 12, principal_type: :user)
      entry = insert(:acl_entry, resource_type: "bar", resource_id: 12, principal_type: :user)

      assert %{id: id} =
               AclEntries.find_by_resource_and_principal(
                 resource_type: "bar",
                 resource_id: 12,
                 user_id: entry.user_id,
                 group_id: nil
               )

      assert id == entry.id
    end
  end

  defp assert_changed(%AclEntry{} = acl_entry, params) do
    fields =
      params
      |> Map.take(AclEntry.__schema__(:fields))
      |> Map.keys()

    assert_maps_equal(acl_entry, params, fields)
  end
end
