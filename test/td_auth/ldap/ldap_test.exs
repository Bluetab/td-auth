defmodule TdAuth.Ldap.LdapTest do
  use TdAuth.DataCase

  alias TdAuth.Ldap.Ldap

  setup_all do
    start_supervised!({TdAuth.Ldap.LdapWorker, nil})
    :ok
  end

  setup do
    ldap_config = Application.get_env(:td_auth, :ldap)

    on_exit(fn ->
      if ldap_config do
        Application.put_env(:td_auth, :ldap, ldap_config)
      else
        Application.delete_env(:td_auth, :ldap)
      end
    end)

    {:ok, %{ldap_config: ldap_config}}
  end

  describe "authenticate/2" do
    test "return valid profile for LDAP" do
      assert {:ok, user_data, _} = Ldap.authenticate("johnsmith", "validPassword")

      assert %{
               email: "a.j.smith@truedat.io",
               full_name: "Abraham",
               user_name: "Abraham J. Smith"
             } = user_data
    end

    test "includes groups for LDAP user", %{ldap_config: ldap_config} do
      allowed_groups = ["manager", "California"]

      new_ldap_config = [
        create_groups: true,
        group_fields: ["objectClass", "customField"],
        allowed_groups: allowed_groups
      ]

      test_ldap_config = Keyword.merge(ldap_config, new_ldap_config)

      Application.put_env(:td_auth, :ldap, test_ldap_config)

      assert {:ok, %{groups: groups}, _} = Ldap.authenticate("johnsmith", "validPassword")

      assert Enum.member?(groups, "California")
      assert Enum.member?(groups, "manager")
      refute Enum.member?(groups, "Los Angeles")
      refute Enum.member?(groups, "West Coast")
      refute Enum.member?(groups, "dev")
      refute Enum.member?(groups, "CTO")
    end
  end
end
