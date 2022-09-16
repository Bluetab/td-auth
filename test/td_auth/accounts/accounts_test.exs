defmodule TdAuth.AccountsTest do
  use TdAuth.DataCase

  alias TdAuth.Accounts

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    start_supervised!(TdAuth.Accounts.GroupLoader)
    :ok
  end

  describe "users" do
    alias TdAuth.Accounts.User

    @valid_attrs %{
      password: "some password",
      user_name: "some user_name",
      email: "some@email.com"
    }
    @update_attrs %{
      password: "some updated password",
      user_name: "some updated user_name",
      email: "someupdated@email.com"
    }
    @invalid_attrs %{password: nil, user_name: nil, email: nil}

    test "list_users/0 returns all users" do
      insert(:user)
      assert length(Accounts.list_users()) == 1
    end

    test "list_users/1 filter users by parametes" do
      insert(:user)
      %{id: id} = insert(:user, role: "service")
      assert [%{id: ^id}] = Accounts.list_users(role: "service")
    end

    test "list_users/1 filters by permission on domains" do
      %{permissions: [permission]} =
        role_1 = insert(:role, name: "role1", permissions: [build(:permission)])

      role_2 = insert(:role, name: "role2", permissions: [permission])

      %{id: user_id_1, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      insert(:user)

      %{resource_id: domain_id_1} = insert(:acl_entry, group_id: group_id, role: role_1)
      %{resource_id: domain_id_2} = insert(:acl_entry, user_id: user_id_2, role: role_2)
      insert(:acl_entry, user_id: user_id_3, role: role_2)

      assert [%{id: ^user_id_1}, %{id: ^user_id_2}] =
               Accounts.list_users(
                 permission_on_domains: {permission.name, [domain_id_1, domain_id_2]}
               )

      assert [%{id: ^user_id_1}] =
               Accounts.list_users(permission_on_domains: {permission.name, [domain_id_1]})

      assert [] =
               Accounts.list_users(permission_on_domains: {"unknown_permission", [domain_id_1]})

      assert [] = Accounts.list_users(permission_on_domains: {permission.name, []})
    end

    test "get_user!/1 returns the user with given id" do
      %{id: user_id} = insert(:user)
      assert %{id: ^user_id} = Accounts.get_user!(user_id)
    end

    test "create_user/1 with valid data creates a user" do
      %{name: group_name} = group = insert(:group)

      params = %{
        "user_name" => "new_user",
        "email" => "email@example.com",
        "password" => "topsecret",
        "groups" => [group.name, "new group"]
      }

      assert {:ok, %User{} = user} = Accounts.create_user(params)

      assert user.password == "topsecret"
      assert user.user_name == "new_user"
      assert [%{name: ^group_name}, %{name: "new group"}] = user.groups
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.password == "some updated password"
      assert user.user_name == "some updated user_name"
      assert user.email == "someupdated@email.com"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user.id == Accounts.get_user!(user.id).id
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, _} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "get_user_by_name/1 return the user with given user_name" do
      user = insert(:user)
      assert Accounts.get_user_by_name(user.user_name).id == user.id
    end

    test "create user always downcase" do
      downcase_name = "downcasename"
      uppercase_name = "DownCaseName"

      {:ok, user} =
        %{password: "some password", user_name: uppercase_name, email: "some@email.com"}
        |> Accounts.create_user()

      assert user.user_name == downcase_name
    end

    test "user_exists? verifies if exists any user without user role" do
      refute Accounts.user_exists?()

      insert(:user, role: :service)
      refute Accounts.user_exists?()

      insert(:user, role: :user)
      refute Accounts.user_exists?()

      insert(:user, role: :admin)
      assert Accounts.user_exists?()
    end
  end

  describe "groups" do
    alias TdAuth.Accounts.Group

    @valid_attrs %{name: "some name", description: "some description"}
    @update_attrs %{name: "some updated name", description: "some updated description"}
    @invalid_attrs %{name: nil}

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_group()

      group
    end

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert Accounts.list_groups() == [group]
    end

    test "list_groups/1 returns all groups with preloads" do
      %{id: user_id} = user = insert(:user)
      %{id: group_id} = insert(:group, users: [user])
      assert [%{id: ^group_id, users: [%{id: ^user_id}]}] = Accounts.list_groups(preload: :users)
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert Accounts.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      assert {:ok, %Group{} = group} = Accounts.create_group(@valid_attrs)
      assert group.name == "some name"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      assert {:ok, group} = Accounts.update_group(group, @update_attrs)
      assert %Group{} = group
      assert group.name == "some updated name"
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_group(group, @invalid_attrs)
      assert group == Accounts.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = Accounts.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_group!(group.id) end
    end

    test "get_user_acls/1 returns the ACLs of a user and its groups" do
      %{id: user_id} = user = insert(:user, groups: [build(:group)])
      %{id: group_id} = hd(user.groups)

      acl_entry_1 = insert(:acl_entry, group_id: group_id)
      acl_entry_2 = insert(:acl_entry, user_id: user_id)

      result = TdAuth.Accounts.get_user_acls(user_id)

      assert_lists_equal(
        result,
        [acl_entry_1, acl_entry_2],
        &assert_structs_equal(&1, &2, [
          :id,
          :description,
          :group_id,
          :resource_id,
          :resource_type,
          :role_id,
          :user_id
        ])
      )
    end

    test "get_user_acls/2 returns the ACLs of a user and its groups with specified preloads" do
      %{id: user_id} = user = insert(:user, groups: [build(:group)])
      %{id: group_id} = hd(user.groups)

      permission = insert(:permission, name: "view_dashboard")
      role = insert(:role, permissions: [permission])

      acl_entry_1 = insert(:acl_entry, group_id: group_id, role: role)
      acl_entry_2 = insert(:acl_entry, user_id: user_id, role: role)

      acl_entries = TdAuth.Accounts.get_user_acls(user_id, [:group, [role: :permissions], :user])

      assert_lists_equal(
        acl_entries,
        [acl_entry_1, acl_entry_2],
        &assert_structs_equal(&1, &2, [
          :id,
          :description,
          :group_id,
          :resource_id,
          :resource_type,
          :role_id,
          :user_id
        ])
      )

      assert Enum.all?(acl_entries, fn acl ->
               [perm | _others] = acl.role.permissions
               %TdAuth.Permissions.Permission{} = perm
               %TdAuth.Permissions.Role{} = acl.role
             end)
    end
  end
end
