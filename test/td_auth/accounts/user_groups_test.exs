defmodule TdAuth.UserGroupsTest do
  use TdAuth.DataCase

  alias TdAuth.Accounts

  setup do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  describe "user groups" do
    @valid_group %{name: "some name", description: "some description"}
    @valid_user %{password: "some password", user_name: "some user_name", email: "some@email.com"}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_user)
        |> Accounts.create_user()
      user
    end

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_group)
        |> Accounts.create_group()

      group
    end

    test "add_groups_to_user/0 adds an association to an existing group" do
      group = group_fixture()
      group_name = group.name
      {:ok, _} = user_fixture()
        |> Accounts.add_groups_to_user([group_name])
      users = Accounts.list_users_by_group_id(group.id)
      assert length(users) == 1
    end

    test "add_groups_to_user/0 adds an association to a new group" do
      group_name = "Foo group"
      {:ok, _} = user_fixture()
        |> Accounts.add_groups_to_user([group_name])
      group = Accounts.get_group_by_name(group_name)
      assert group.name == group_name
      users = Accounts.list_users_by_group_id(group.id)
      assert length(users) == 1
    end

    test "add_groups_to_user/0 adds associations to an existing group and to a new group" do
      existing_group = group_fixture()
      new_group_name = "Foo group"
      {:ok, _} = user_fixture()
        |> Accounts.add_groups_to_user([existing_group.name, new_group_name])
      new_group = Accounts.get_group_by_name(new_group_name)
      assert new_group.name == new_group_name
      assert length(Accounts.list_users_by_group_id(new_group.id)) == 1
      assert length(Accounts.list_users_by_group_id(existing_group.id)) == 1
    end

    test "add_groups_to_user/0 adds multiple users to a group" do
      user1 = user_fixture(%{user_name: "user1"})
      user2 = user_fixture(%{user_name: "user2"})
      group = group_fixture()
      {:ok, _} = user1 |> Accounts.add_groups_to_user([group.name])
      {:ok, _} = user2 |> Accounts.add_groups_to_user([group.name])
      users = Accounts.list_users_by_group_id(group.id)
      assert length(users) == 2
    end

  end
end
