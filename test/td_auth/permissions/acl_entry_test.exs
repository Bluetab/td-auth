defmodule TdAuth.Permissions.AclEntryTest do
  use TdAuth.DataCase

  alias Ecto.Changeset
  alias TdAuth.Permissions.AclEntry

  setup context do
    Enum.reduce(context, %{}, fn
      {:acl_entry, attrs}, ctx ->
        Map.put(ctx, :acl_entry, insert(:acl_entry, attrs))

      {:user, attrs}, ctx ->
        Map.put(ctx, :user, insert(:user, attrs))

      {:role, attrs}, ctx ->
        Map.put(ctx, :role, insert(:role, attrs))

      _, ctx ->
        ctx
    end)
  end

  describe "acl_entries" do
    test "changes/1 casts valid parameters to a map" do
      attrs = %{
        "user_id" => "1234",
        "resource_type" => "books",
        "role_id" => "32",
        "group_id" => nil,
        "foo" => "bar"
      }

      assert AclEntry.changes(attrs) == %{
               user_id: 1234,
               resource_type: "book",
               role_id: 32
             }
    end

    @tag acl_entry: %{}
    test "changeset/2 validates required fields" do
      assert %Changeset{errors: errors} = AclEntry.changeset(%AclEntry{}, %{})

      assert {_, [validation: :required]} = errors[:resource_type]
      assert {_, [validation: :required]} = errors[:resource_id]
      assert {_, [validation: :required]} = errors[:role_id]
    end

    test "changeset/2 validates inclusion on resource_type" do
      acl_entry = insert(:acl_entry)

      assert %Changeset{errors: errors} =
               AclEntry.changeset(acl_entry, %{resource_type: "foo"})

      assert {_, [validation: :inclusion, enum: _]} = errors[:resource_type]
    end

    test "changeset/2 validates length of description" do
      acl_entry = insert(:acl_entry)
      description = String.pad_leading("foo", 130, "bar")

      assert %Changeset{errors: errors} =
               AclEntry.changeset(acl_entry, %{description: description})

      assert {_, [count: 120, validation: :length, kind: :max, type: :string]} =
               errors[:description]
    end

    test "changeset/2 changes group_id to nil if user_id is changed" do
      acl_entry = insert(:acl_entry, principal_type: :user)
      assert %Changeset{changes: changes} = AclEntry.changeset(acl_entry, %{group_id: 123})
      assert %{user_id: nil, group_id: 123} = changes
    end

    test "changeset/2 changes user_id to nil if group_id is changed" do
      acl_entry = insert(:acl_entry, principal_type: :group)
      assert %Changeset{changes: changes} = AclEntry.changeset(acl_entry, %{user_id: 123})
      assert %{user_id: 123, group_id: nil} = changes
    end
  end
end
