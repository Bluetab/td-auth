defmodule TdAuth.Accounts.UserTest do
  use TdAuth.DataCase

  alias Ecto.Changeset
  alias TdAuth.Accounts.User

  setup context do
    Enum.reduce(context, %{}, fn
      {:user, attrs}, ctx ->
        Map.put(ctx, :user, insert(:user, attrs))

      _, ctx ->
        ctx
    end)
  end

  describe "TdAuth.Accounts.User" do
    test "changeset/2 validates required fields" do
      assert %Changeset{errors: errors} = changeset = User.changeset(%{})

      refute changeset.valid?
      assert {_, [validation: :required]} = errors[:email]
      assert {_, [validation: :required]} = errors[:user_name]
    end

    test "changeset/2 validates length fields" do
      assert %Changeset{errors: errors} = changeset = User.changeset(%{password: "foo"})

      refute changeset.valid?
      assert {_, [count: 6, validation: :length, kind: min, type: :string]} = errors[:password]
    end

    test "changeset/2 puts password_hash if password is valid" do
      user = insert(:user)

      assert %Changeset{changes: changes} = User.changeset(user, %{password: "secret"})
      assert Map.has_key?(changes, :password_hash)
    end

    test "changeset/2 changes user_name to lower case" do
      assert %Changeset{changes: changes} =
               changeset =
               User.changeset(%{password: "secret", email: "email@example.com", user_name: "FOO"})

      assert changeset.valid?
      assert changes[:user_name] == "foo"
    end

    test "changeset/2 replaces groups association" do
      group = insert(:group)
      user = insert(:user, groups: [build(:group), build(:group)])

      assert %Changeset{changes: changes} =
               changeset = User.changeset(user, %{"groups" => [group]})

      assert changeset.valid?

      assert [
               %Changeset{action: :replace},
               %Changeset{action: :replace},
               %Changeset{action: :update}
             ] = changes[:groups]
    end

    test "changeset/2 replaces groups association with empty" do
      user = insert(:user, groups: [build(:group), build(:group)])

      assert %Changeset{changes: changes} = changeset = User.changeset(user, %{"groups" => []})

      assert changeset.valid?

      assert [
               %Changeset{action: :replace},
               %Changeset{action: :replace}
             ] = changes[:groups]
    end

    test "changeset captures unique constraint on user_name" do
      alias TdAuth.Repo

      %{user_name: user_name} = insert(:user)

      params = %{
        user_name: user_name,
        email: "some@example.com",
        password: "secret"
      }

      assert {:error, %Changeset{errors: errors} = changeset} =
               params
               |> User.changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert {_, [constraint: :unique, constraint_name: _]} = errors[:user_name]
    end
  end
end
