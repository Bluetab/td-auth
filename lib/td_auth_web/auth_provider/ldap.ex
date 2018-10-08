defmodule TdAuthWeb.AuthProvider.Ldap do
  @moduledoc false
  require Logger

  alias Gettext.Interpolation
  alias Poison, as: JSON

  def authenticate(user_name, password) do
    case ldap_authenticate(user_name, password) do
      {:ok} -> create_profile(user_name)
      error -> error
    end
  end

  defp ldap_authenticate(user_name, password) do
    case ldap_open() do
      {:ok, conn} ->
        ldap_verify(conn, user_name, password)
      error ->
        Logger.info("Error while opening ldap connection... #{inspect(error)}")
        error
    end
  end

  defp ldap_open do
    Exldap.open(get_ldap_server(), get_ldap_port(),
                get_ldap_ssl(), get_ldap_connection_timeout())
  end

  defp ldap_verify(conn, user_name, password) do
    bind = get_ldap_bind(user_name)
    case Exldap.verify_credentials(conn, bind, password) do
      :ok -> {:ok}
      error ->
        Logger.info("Error while ldap user_name password verification... #{inspect(error)}")
        error
    end
  end

  defp get_ldap_bind(user_name) do
    bind_pattern = get_ldap_bind_pattern()
    bind_pattern
    |> Interpolation.to_interpolatable
    |> Interpolation.interpolate(%{user_name: user_name})
    |> elem(1)
  end

  defp create_profile(user_name) do
    case ldap_connect() do
      {:ok, conn} ->
        case ldap_search(conn, user_name) do
          {:ok, search_results} ->
            build_profile(search_results)
          error ->
            Logger.info("Error while searching user... #{inspect(error)}")
            error
        end
      error ->
        Logger.info("Error while connecting to ldap... #{inspect(error)}")
        error
    end
  end

  defp ldap_connect do
    Exldap.connect(get_ldap_server(), get_ldap_port(),
                   get_ldap_ssl(), get_ldap_user_dn(),
                   get_ldap_password(), get_ldap_connection_timeout())
  end

  defp ldap_search(conn, user_name) do
    Exldap.search_field(conn, get_ldap_search_path(),
                        get_ldap_search_field(), user_name)
  end

  defp build_profile(search_results) do
    case  Enum.fetch(search_results, 0) do
      {:ok, entry} ->
        mapping = get_ldap_profile_mapping()
        profile = Enum.reduce(mapping, %{}, fn({k, v}, acc) ->
          attr = Exldap.get_attribute!(entry, v)
          Map.put(acc, k, attr)
        end)
        {:ok, profile}
      error ->
        Logger.info("Error while building profile... #{inspect(error)}")
        error
    end
  end

  defp get_ldap_server do
    Application.get_env(:td_auth, :ldap)[:server]
  end

  # defp get_ldap_base do
  #   Application.get_env(:td_auth, :ldap)[:base]
  # end

  defp get_ldap_port do
    port = Application.get_env(:td_auth, :ldap)[:port]
    String.to_integer(port)
  end

  defp get_ldap_ssl do
    ssl = Application.get_env(:td_auth, :ldap)[:ssl]
    if ssl == "true", do: true, else: false
  end

  def get_ldap_user_dn do
    Application.get_env(:td_auth, :ldap)[:user_dn]
  end

  defp get_ldap_password do
    Application.get_env(:td_auth, :ldap)[:password]
  end

  defp get_ldap_profile_mapping do
    ldap_config = Application.get_env(:td_auth, :ldap)
    JSON.decode!(ldap_config[:profile_mapping])
  end

  defp get_ldap_bind_pattern do
    Application.get_env(:td_auth, :ldap)[:bind_pattern]
  end

  defp get_ldap_search_path do
    Application.get_env(:td_auth, :ldap)[:search_path]
  end

  defp get_ldap_search_field do
    Application.get_env(:td_auth, :ldap)[:search_field]
  end

  def get_ldap_connection_timeout do
    timeout = Application.get_env(:td_auth, :ldap)[:connection_timeout]
    String.to_integer(timeout)
  end

end
