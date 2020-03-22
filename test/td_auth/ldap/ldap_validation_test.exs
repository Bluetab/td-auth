defmodule TdAuth.LdapValidationTest do
  use TdAuth.DataCase

  alias TdAuth.Ldap.EldapMock
  alias TdAuth.Ldap.LdapValidation
  alias TdAuth.Ldap.LdapWorker

  setup_all do
    start_supervised!({TdAuth.Ldap.LdapWorker, nil})
    start_supervised!(EldapMock)
    :ok
  end

  def attribute_doesnt_have_value(_) do
    attribute = "ldap_attribute"
    value = "attribute_value"
    other_value = "other_attribute_value"

    LdapWorker.set_validations([
      %{
        "type" => "attribute_doesnt_have_value",
        "attribute" => attribute,
        "value" => value
      }
    ])

    {:ok, attribute: attribute, value: value, other_value: other_value}
  end

  describe "validation type attribute_doesnt_have_value" do
    setup [:attribute_doesnt_have_value]

    test "returns error if attribute has value", %{
      attribute: attribute,
      value: value
    } do
      EldapMock.set_attribute_value(attribute, value)

      expected = {
        :ldap_error,
        %{attribute: attribute, type: :unwanted_value_on_attribute, value: value}
      }

      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end

    test "returns ok if attribute doesnt has value", %{
      attribute: attribute,
      other_value: other_value
    } do
      EldapMock.set_attribute_value(attribute, other_value)

      expected = {:ok, []}
      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end
  end

  def attribute_has_value(_) do
    attribute = "ldap_attribute"
    value = "attribute_value"
    other_value = "other_attribute_value"

    LdapWorker.set_validations([
      %{
        "type" => "attribute_has_value",
        "attribute" => attribute,
        "value" => value
      }
    ])

    {:ok, attribute: attribute, value: value, other_value: other_value}
  end

  describe "validation type attribute_has_value" do
    setup [:attribute_has_value]

    test "returns error if attribute doesnt has value", %{
      attribute: attribute,
      value: value,
      other_value: other_value
    } do
      EldapMock.set_attribute_value(attribute, other_value)

      expected = {
        :ldap_error,
        %{attribute: attribute, type: :missing_value_on_attribute, value: value}
      }

      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end

    test "returns ok if attribute has value", %{
      attribute: attribute,
      value: value
    } do
      EldapMock.set_attribute_value(attribute, value)

      expected = {:ok, []}
      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end
  end

  def expiration_date_attribute(_) do
    attribute = "ldap_attribute"
    expiration_in_days = 10

    LdapWorker.set_validations([
      %{
        "type" => "expiration_date_attribute",
        "attribute" => attribute,
        "expiration_in_days" => expiration_in_days
      }
    ])

    {:ok, attribute: attribute, expiration_in_days: expiration_in_days}
  end

  describe "validation type expiration_date_attribute" do
    setup [:expiration_date_attribute]

    test "will add warning indicating numbers of days until expires", %{
      attribute: attribute,
      expiration_in_days: expiration_in_days
    } do
      expiration_date =
        Date.utc_today()
        |> Date.to_iso8601(:basic)

      EldapMock.set_attribute_value(attribute, expiration_date)

      expected = {:ok, [["days_to_expire", expiration_in_days]]}
      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end

    test "will add warning indicating 0 days when expiration date is today", %{
      attribute: attribute,
      expiration_in_days: expiration_in_days
    } do
      expiration_date =
        Date.utc_today()
        |> Date.add(expiration_in_days * -1)
        |> Date.to_iso8601(:basic)

      EldapMock.set_attribute_value(attribute, expiration_date)

      expected = {:ok, [["days_to_expire", 0]]}
      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end

    test "will add warning indicating negative number when expired", %{
      attribute: attribute,
      expiration_in_days: expiration_in_days
    } do
      expiration_date =
        Date.utc_today()
        |> Date.add(expiration_in_days * -1)
        |> Date.add(-5)
        |> Date.to_iso8601(:basic)

      EldapMock.set_attribute_value(attribute, expiration_date)

      expected = {:ok, [["days_to_expire", -5]]}
      assert expected == LdapValidation.validate_entry(:conn, :entry)
    end
  end
end
