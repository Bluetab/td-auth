defmodule TdAuth.Ldap.EldapMock do
  @moduledoc false

  use GenServer

  def start_link(_, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def get_attribute_value(attribute) do
    GenServer.call(__MODULE__, {:get_attribute_value, attribute})
  end

  def set_attribute_value(attribute, value) do
    GenServer.cast(__MODULE__, {:set_attribute_value, attribute, value})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:get_attribute_value, attribute}, _, attrs) do
    {:reply, Map.get(attrs, to_charlist(attribute)), attrs}
  end

  @impl true
  def handle_cast({:set_attribute_value, attribute, value}, attrs) do
    {:noreply, Map.put(attrs, to_charlist(attribute), to_charlist(value))}
  end

  def open(
        _get_ldap_server_fn,
        _get_ldap_port_fn,
        _get_ldap_ssl_fn,
        _get_ldap_connection_timeout_fn
      ) do
    {:ok, self()}
  end

  def connect(
        _get_ldap_server_fn,
        _get_ldap_port_fn,
        _get_ldap_ssl_fn,
        _get_ldap_user_dn_fn,
        _get_ldap_password_fn,
        _get_ldap_connection_timeout_fn
      ) do
    {:ok, self()}
  end

  def verify_credentials(_conn, _get_ldap_user_dn_fn, _get_ldap_password_fn) do
    :ok
  end

  def search_field(_conn, _get_ldap_search_path_fn, _get_ldap_search_field_fn, _user_name) do
    {:ok,
     [
       %Exldap.Entry{
         object_name: 'cn=Abraham J. Smith,ou=people,dc=bluetab,dc=net',
         attributes: [
           {'uid', ['johnsmith']},
           {'cn', ['Abraham J. Smith']},
           {'givenName', ['Abraham']},
           {'mail', ['a.j.smith@truedat.io']},
           {'objectClass', ['Los Angeles', 'California', 'West Coast']},
           {'customField', ['dev', 'manager', 'CTO']}
         ]
       }
     ]}
  end

  def close(_conn) do
    :ok
  end

  def search(_conn, keywords) do
    attribute =
      keywords
      |> Keyword.get(:attributes)
      |> hd

    values =
      case get_attribute_value(attribute) do
        nil -> []
        value -> [value]
      end

    attributes = [{attribute, values}]

    search_result = {
      :eldap_search_result,
      [{:eldap_entry, nil, attributes}],
      nil
    }

    {:ok, search_result}
  end

  def get_attribute!(_, _), do: nil
end
