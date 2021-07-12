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
      assert {_, [validation: :required]} = errors[:user_name]
    end

    test "validates length fields" do
      assert %Changeset{errors: errors} = changeset = User.changeset(%{password: "foo"})

      refute changeset.valid?
      assert {_, [count: 6, validation: :length, kind: :min, type: :string]} = errors[:password]
    end

    test "permits missing email" do
      %Changeset{} = changeset = User.changeset(%{user_name: "foo"})
      assert changeset.valid?
    end

    test "permits nil email" do
      user = insert(:user)
      %Changeset{} = changeset = User.changeset(user, %{user_name: "foo", email: nil})
      assert changeset.valid?
      assert Changeset.fetch_change(changeset, :email) == {:ok, nil}
    end

    test "puts password_hash if password is valid" do
      user = insert(:user)

      assert %Changeset{changes: changes} = User.changeset(user, %{password: "secret"})
      assert Map.has_key?(changes, :password_hash)
    end

    test "update password when password is valid" do
      user = insert(:user)

      assert {:ok, %TdAuth.Accounts.User{}} =
               user
               |> User.changeset(%{password: "new_secret", old_password: "secret hash"})
               |> Repo.update()
    end

    test "validate update password when password is invalid" do
      user = insert(:user)

      assert {:error, changeset} =
               user
               |> User.changeset(%{password: "new", old_password: "invalid_password"})
               |> Repo.update()

      assert %{
               old_password: ["Invalid old password"],
               password: ["should be at least 6 character(s)"]
             } ==
               traverse_errors(changeset, fn {msg, opts} ->
                 Enum.reduce(opts, msg, fn {key, value}, acc ->
                   String.replace(acc, "%{#{key}}", to_string(value))
                 end)
               end)
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

    test "keeps groups association" do
      group = insert(:group)
      user = insert(:user, groups: [build(:group), build(:group)])

      assert %Changeset{changes: changes} =
               changeset = User.changeset(user, %{"groups" => [group]}, true)

      assert changeset.valid?

      assert [
               %Changeset{action: :update},
               %Changeset{action: :update},
               %Changeset{action: :update}
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
  end
end
