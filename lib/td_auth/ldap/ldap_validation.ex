defmodule TdAuth.Ldap.LdapValidation do
  @moduledoc false

  alias TdAuth.Ldap.Ldap
  alias TdAuth.Ldap.LdapWorker

  require Logger

  @eldap_module Application.compile_env(:td_auth, :eldap_module)
  @exldap_module Application.compile_env(:td_auth, :exldap_module)

  def validate_entry(conn, entry) do
    validations = LdapWorker.get_validations()
    validate_entry(conn, entry, validations)
  end

  defp validate_entry(_, _, []), do: {:ok, []}

  defp validate_entry(conn, entry, validations) do
    cn = @exldap_module.get_attribute!(entry, "cn")
    filter = :eldap.substrings(~c"cn", any: cn)
    validate_entry(conn, filter, validations, [])
  end

  defp validate_entry(_, _, [], warnings), do: {:ok, warnings}

  defp validate_entry(conn, filter, [validation | remaining_validations], warnings) do
    case run_validation(conn, filter, validation) do
      {:ok, nil} -> validate_entry(conn, filter, remaining_validations, warnings)
      {:ok, warning} -> validate_entry(conn, filter, remaining_validations, [warning | warnings])
      error -> {:ldap_error, error}
    end
  end

  defp run_validation(conn, filter, %{
         "type" => "attribute_has_value",
         "attribute" => attribute,
         "value" => value
       }) do
    has_value = attribute_has_value(conn, filter, attribute, value)

    case has_value do
      true ->
        {:ok, nil}

      _ ->
        %{
          type: :missing_value_on_attribute,
          attribute: attribute,
          value: value
        }
    end
  end

  defp run_validation(conn, filter, %{
         "type" => "attribute_doesnt_have_value",
         "attribute" => attribute,
         "value" => value
       }) do
    has_value = attribute_has_value(conn, filter, attribute, value)

    case has_value do
      false ->
        {:ok, nil}

      _ ->
        %{
          type: :unwanted_value_on_attribute,
          attribute: attribute,
          value: value
        }
    end
  end

  defp run_validation(conn, filter, %{
         "type" => "expiration_date_attribute",
         "attribute" => attribute,
         "expiration_in_days" => expiration
       }) do
    values = get_attribute_values(conn, filter, attribute)

    case values do
      [date_charlist] ->
        date_string = to_string(date_charlist)
        date_regex = ~r/^(\d{4})(\d{2})(\d{2})/
        [_, year, month, day] = Regex.run(date_regex, date_string)

        {:ok, date} =
          Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))

        date_expire = Date.add(date, expiration)
        today = Date.utc_today()
        date_diff = Date.diff(date_expire, today)
        {:ok, ["days_to_expire", date_diff]}

      [] ->
        {:ok, nil}
    end
  end

  defp run_validation(_, _, _), do: {:ok, nil}

  defp attribute_has_value(conn, filter, attribute, value) do
    charlist_value = to_charlist(value)

    conn
    |> get_attribute_values(filter, attribute)
    |> Enum.member?(charlist_value)
  end

  defp get_attributes_from_search({
         :eldap_search_result,
         [{:eldap_entry, _, attributes} | _],
         _
       }),
       do: attributes

  defp get_attributes_from_search(_), do: []

  defp get_values_from_entry([{attribute, values}], attribute), do: values
  defp get_values_from_entry(_, _), do: []

  defp get_attribute_values(conn, filter, attribute) do
    charlist_attr = to_charlist(attribute)

    {:ok, search_result} =
      @eldap_module.search(conn,
        base: Ldap.get_ldap_search_path(),
        filter: filter,
        attributes: [charlist_attr]
      )

    search_result
    |> get_attributes_from_search
    |> get_values_from_entry(charlist_attr)
  end
end
