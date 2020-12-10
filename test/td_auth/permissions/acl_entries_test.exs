defmodule TdAuth.Permissions.AclEntriesTest do
  use TdAuth.DataCase

  alias Ecto.Changeset
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry

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
    start_supervised(TdAuth.Permissions.AclLoader)
    :ok
  end

  describe "TdAuth.Permissions.AclEntries" do
    test "get_acl_entry!/1 returns the acl_entry with given id" do
      %{id: id} = insert(:acl_entry, resource_type: "foo", resource_id: 1)
      assert %{id: ^id} = AclEntries.get_acl_entry!(id)
    end

    test "list_acl_entries/0 returns a list of acl entries" do
      %{id: id1} = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      %{id: id2} = insert(:acl_entry, resource_type: "bar", resource_id: 2)

      assert [%{id: ^id1}, %{id: ^id2}] = AclEntries.list_acl_entries()
    end

    test "list_acl_entries/1 returns a list of acl entries for a specified resource" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      _e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99)
      e3 = insert(:acl_entry, resource_type: "foo", resource_id: 12)

      result = AclEntries.list_acl_entries(resource_type: "foo", resource_id: 12)
      assert_lists_equal(result, [e1, e3], &assert_structs_equal(&1, &2, @acl_entry_keys))
    end

    test "create_acl_entry/1 with valid params creates an ACL entry and refreshes cache" do
      alias TdCache.AclCache

      %{id: user_id} = insert(:user)
      %{id: role_id, name: role_name} = insert(:role)

      %{resource_id: resource_id} =
        params = %{
          resource_id: :rand.uniform(10_000),
          resource_type: "domain",
          role_id: role_id,
          user_id: user_id
        }

      assert {:ok, acl_entry = %AclEntry{}} = AclEntries.create_acl_entry(params)
      assert_changed(acl_entry, params)
      assert "#{user_id}" in AclCache.get_acl_role_users("domain", resource_id, role_name)
      assert role_name in AclCache.get_acl_roles("domain", resource_id)
    end

    test "create_acl_entry/1 enforces unique constraint on user_id and resource" do
      assert {:error, %Changeset{errors: errors}} =
               :acl_entry
               |> insert(principal_type: :user)
               |> Map.take([:user_id, :resource_type, :resource_id, :role_id])
               |> AclEntries.create_acl_entry()

      assert {_, [constraint: :unique, constraint_name: _]} = errors[:user_id]
    end

    test "create_acl_entry/1 enforces unique constraint on group_id and resource" do
      assert {:error, changeset = %Changeset{errors: errors}} =
               :acl_entry
               |> insert(principal_type: :group)
               |> Map.take([:group_id, :resource_type, :resource_id, :role_id])
               |> AclEntries.create_acl_entry()

      refute changeset.valid?
      assert {_, [constraint: :unique, constraint_name: _]} = errors[:group_id]
    end

    test "create_acl_entry/1 enforces foreign key constraint on user_id" do
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

    test "create_acl_entry/1 enforces foreign key constraint on group_id" do
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

    test "create_acl_entry/1 enforces foreign key constraint on role_id" do
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

    test "create_acl_entry/1 enforces check constraint on user_id and group_id" do
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

    test "delete_acl_entry/1 deletes the ACL Entry" do
      acl_entry = insert(:acl_entry)
      assert {:ok, %AclEntry{}} = AclEntries.delete_acl_entry(acl_entry)
    end

    test "delete_acl_entries/1 applies filters" do
      e1 = insert(:acl_entry, resource_type: "foo", resource_id: 12)
      _e2 = insert(:acl_entry, resource_type: "foo", resource_id: 99)
      e3 = insert(:acl_entry, resource_type: "foo", resource_id: 12)

      assert {2, entries} =
               AclEntries.delete_acl_entries(resource_type: "foo", resource_id: {:not_in, [99]})

      assert_lists_equal(entries, [e1, e3], &assert_structs_equal(&1, &2, @acl_entry_keys))
    end

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
