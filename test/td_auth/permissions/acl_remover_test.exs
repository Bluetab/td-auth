defmodule TdAuth.Permissions.AclRemoverTest do
  use ExUnit.Case, async: true

  alias TdAuth.Permissions.AclRemover

  describe "delete_stale_acl_entries/0" do
    test "is a function that can be called" do
      assert is_function(&AclRemover.delete_stale_acl_entries/0, 0)
    end

    test "can be called without errors" do
      result = AclRemover.delete_stale_acl_entries()
      assert result == :ok or result == []
    end
  end
end
