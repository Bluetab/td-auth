defmodule TdAuth.Accounts.UserTest do
  use TdAuth.DataCase

  alias Ecto.Changeset
  alias TdAuth.Accounts.User
  alias TdAuth.Repo

  setup context do
    Enum.reduce(context, %{}, fn
      {:user, attrs}, ctx ->
        Map.put(ctx, :user, insert(:user, attrs))

      _, ctx ->
        ctx
    end)
  end

  describe "changeset/2" do
    test "validates required fields" do
      assert %Changeset{errors: errors} = changeset = User.changeset(%{})

      refute changeset.valid?
      assert {_, [validation: :required]} = errors[:email]
      assert {_, [validation: :required]} = errors[:user_name]
    end

    test "validates length fields" do
      assert %Changeset{errors: errors} = changeset = User.changeset(%{password: "foo"})

      refute changeset.valid?
      assert {_, [count: 6, validation: :length, kind: :min, type: :string]} = errors[:password]
    end

    test "puts password_hash if password is valid" do
      user = insert(:user)

      assert %Changeset{changes: changes} = User.changeset(user, %{password: "secret"})
      assert Map.has_key?(changes, :password_hash)
    end

    test "changes user_name to lower case" do
      assert %Changeset{changes: changes} =
               changeset =
               User.changeset(%{password: "secret", email: "email@example.com", user_name: "FOO"})

      assert changeset.valid?
      assert changes[:user_name] == "foo"
    end

    test "replaces groups association" do
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

    test "replaces groups association with empty" do
      user = insert(:user, groups: [build(:group), build(:group)])

      assert %Changeset{changes: changes} = changeset = User.changeset(user, %{"groups" => []})

      assert changeset.valid?

      assert [
               %Changeset{action: :replace},
               %Changeset{action: :replace}
             ] = changes[:groups]
    end

    test "captures unique constraint on user_name" do
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

    test "validates role" do
      params = %{password: "secret", email: "foo@bar.com", user_name: "foo", role: :foo}

      assert %Changeset{valid?: false, errors: errors} = User.changeset(params)
      assert errors[:role]

      params = %{password: "secret", email: "foo@bar.com", user_name: "foo", role: "service"}
      assert %Changeset{valid?: true} = User.changeset(params)
    end

    test "is inserted with role :user if no role is specified" do
      assert {:ok, %{role: :user}} =
               %{password: "secret", email: "email@example.com", user_name: "foo"}
               |> User.changeset()
               |> Repo.insert()
    end

    test "puts admin role if is_admin is specified" do
      assert %Changeset{changes: changes} =
               changeset =
               User.changeset(%{
                 password: "secret",
                 email: "email@example.com",
                 user_name: "foo",
                 is_admin: true
               })

      assert changeset.valid?
      assert changes[:role] == :admin
    end
  end
end
