defmodule TdAuth.PermissionsTest do
  use TdAuth.DataCase

  alias TdAuth.Permissions
  alias TdAuth.Permissions.Permission

  describe "permissions" do
    test "list_permissions/0 returns all permissions" do
      current_permissions = Permission.permissions() |> Map.values() |> Enum.sort()

      stored_permissions =
        Permissions.list_permissions() |> Enum.map(&Map.get(&1, :name)) |> Enum.sort()

      assert current_permissions == stored_permissions
    end

    test "get_permission!/1 returns the premission with given id" do
      permission = List.first(Permissions.list_permissions())
      assert Permissions.get_permission!(permission.id) == permission
    end

  end
end
