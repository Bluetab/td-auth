defmodule TdAuth.AccountsTest do
  use TdAuth.DataCase

  alias TdAuth.Accounts

  describe "users" do
    alias TdAuth.Accounts.User

    @valid_attrs %{password: "some password", user_name: "some user_name", email: "some@email.com"}
    @update_attrs %{password: "some updated password", user_name: "some updated user_name", email: "someupdated@email.com"}
    @invalid_attrs %{password: nil, user_name: nil, email: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()
      user
    end

    test "list_users/0 returns all users" do
      user_fixture()
      assert length(Accounts.list_users()) == 2
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      #assert Accounts.get_user!(user.id) == user
      assert Accounts.get_user!(user.id).id == user.id
    end
    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)

      assert user.password == "some password"
      assert user.user_name == "some user_name"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.password == "some updated password"
      assert user.user_name == "some updated user_name"
      assert user.email == "someupdated@email.com"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user.id == Accounts.get_user!(user.id).id
#      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      #assert {:ok, %User{}} = Accounts.delete_user(user)
      assert {:ok, _} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "get_user_by_name/1 return the user with given user_name" do
      user = user_fixture()
      #assert Accounts.get_user_by_name(user.user_name) == user
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
  end
end
