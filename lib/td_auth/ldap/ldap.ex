defmodule TdAuth.Ldap.Ldap do
  @moduledoc false

  alias Gettext.Interpolation.Default
  alias TdAuth.Ldap.LdapValidation

  require Logger

  @exldap_module Application.compile_env(:td_auth, :exldap_module)

  def authenticate(user_name, password) do
    case ldap_authenticate() do
      :ok -> create_profile(user_name, password)
      error -> error
    end
  end

  defp ldap_authenticate do
    case ldap_open() do
      {:ok, conn} ->
        try do
          @exldap_module.verify_credentials(conn, get_ldap_user_dn(), get_ldap_password())
        after
          ldap_close(conn)
        end

      error ->
        Logger.info("Error while opening ldap connection... #{inspect(error)}")
        error
    end
  end

  defp ldap_open do
    @exldap_module.open(
      get_ldap_server(),
      get_ldap_port(),
      get_ldap_ssl(),
      get_ldap_connection_timeout()
    )
  end

  defp ldap_close(conn) do
    @exldap_module.close(conn)
  end

  defp create_profile(user_name, password) do
    case ldap_connect() do
      {:ok, conn} ->
        try do
          with {:ok, search_results} <- ldap_search(conn, user_name),
               {:ok, entry} <- fetch_ldap_entry(search_results),
               {:ok, profile} <- verify_user_credentials(conn, user_name, password, entry),
               {:ok, warnings} <- LdapValidation.validate_entry(conn, entry) do
            {:ok, profile, warnings}
          end
        after
          ldap_close(conn)
        end

      error ->
        Logger.info("Error while connecting to ldap... #{inspect(error)}")
        error
    end
  end

  defp verify_user_credentials(conn, user_name, password, entry) do
    object_name = Map.get(entry, :object_name)

    case verify_credentials(conn, user_name, password, object_name) do
      :ok ->
        profile = build_profile(entry)
        {:ok, profile}

      {:error, error} ->
        {:ldap_error, %{type: error}}
    end
  end

  defp verify_credentials(conn, user_name, password, nil) do
    bind = get_ldap_bind(user_name)
    @exldap_module.verify_credentials(conn, bind, password)
  end

  defp verify_credentials(conn, _user_name, password, object_name) do
    @exldap_module.verify_credentials(conn, object_name, password)
  end

  defp get_ldap_bind(user_name) do
    bind_pattern = get_ldap_bind_pattern()

    {:ok, res} = Default.runtime_interpolate(bind_pattern, %{user_name: user_name})

    res
  end

  defp ldap_connect do
    @exldap_module.connect(
      get_ldap_server(),
      get_ldap_port(),
      get_ldap_ssl(),
      get_ldap_user_dn(),
      get_ldap_password(),
      get_ldap_connection_timeout()
    )
  end

  defp ldap_search(conn, user_name) do
    @exldap_module.search_field(conn, get_ldap_search_path(), get_ldap_search_field(), user_name)
  end

  defp build_profile(entry) do
    mapping = get_ldap_profile_mapping()

    Enum.reduce(mapping, %{}, fn {k, v}, acc ->
      attr = Exldap.get_attribute!(entry, v)
      Map.put(acc, k, attr)
    end)
    |> maybe_put_groups(entry, Application.get_env(:td_auth, :ldap)[:create_groups])
  end

  defp fetch_ldap_entry(search_results) do
    Enum.fetch(search_results, 0)
  end

  defp get_ldap_server do
    Application.get_env(:td_auth, :ldap)[:server]
  end

  defp get_ldap_port do
    port = Application.get_env(:td_auth, :ldap)[:port]
    String.to_integer(port)
  end

  defp get_ldap_ssl do
    Application.get_env(:td_auth, :ldap)[:ssl] == "true"
  end

  def get_ldap_user_dn do
    Application.get_env(:td_auth, :ldap)[:user_dn]
  end

  defp get_ldap_password do
    Application.get_env(:td_auth, :ldap)[:password]
  end

  defp get_ldap_profile_mapping do
    Application.get_env(:td_auth, :ldap)[:profile_mapping]
  end

  defp get_ldap_bind_pattern do
    Application.get_env(:td_auth, :ldap)[:bind_pattern]
  end

  def get_ldap_search_path do
    Application.get_env(:td_auth, :ldap)[:search_path]
  end

  defp get_ldap_search_field do
    Application.get_env(:td_auth, :ldap)[:search_field]
  end

  def get_ldap_connection_timeout do
    timeout = Application.get_env(:td_auth, :ldap)[:connection_timeout]
    String.to_integer(timeout)
  end

  defp maybe_put_groups(
         profile,
         %{object_name: entryObjectName, attributes: entryAttributes},
         true
       ) do
    fields = Application.get_env(:td_auth, :ldap)[:group_fields]

    allowed_groups = Application.get_env(:td_auth, :ldap)[:allowed_groups]

    attributes_groups =
      entryAttributes
      |> Enum.filter(fn {key, _} -> Enum.member?(fields, to_string(key)) end)
      |> Enum.flat_map(fn {_, value} -> value end)
      |> Enum.map(&to_string/1)

    param_groups =
      Regex.scan(~r/,ou=([^,]+)/, List.to_string(entryObjectName))
      |> Enum.map(fn [_, name] -> name end)

    groups =
      [attributes_groups, param_groups]
      |> Enum.concat()
      |> Enum.uniq()
      |> Enum.filter(&Enum.member?(allowed_groups, &1))

    Map.put(profile, :groups, groups)
  end

  defp maybe_put_groups(profile, _, _), do: profile
end
