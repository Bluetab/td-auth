defmodule TdAuthWeb.AuthProvider.ActiveDirectory do
  @moduledoc false
  require Logger

  @samaccountname "sAMAccountName"
  @distinguised_name "distinguishedName"
  @user_name "user_name"
  @user_dn "user_dn"

  def authenticate(user_name, password) do
    case create_profile(user_name) do
      {:ok, profile} ->
        case ldap_authenticate(profile, password)  do
          {:ok} -> {:ok, profile}
          error -> error
        end
      error -> error
    end
  end

  defp ldap_authenticate(profile, password) do
    case ldap_open() do
      {:ok, conn} ->
        try do
          user_dn = Map.get(profile, @user_dn)
          ldap_verify(conn, user_dn, password)
        after
          ldap_close(conn)
        end
      error ->
        Logger.info("Error while opening active directory connection... #{inspect(error)}")
        error
    end
  end

  defp ldap_open do
    Exldap.open(get_ad_server(), get_ad_port(),
                get_ad_ssl(), get_ad_connection_timeout())
  end

  defp ldap_verify(conn, user_dn, password) do
    case Exldap.verify_credentials(conn, user_dn, password) do
      :ok -> {:ok}
      error ->
        Logger.info("Error while active directory user_name password verification... #{inspect(error)}")
        error
    end
  end

  defp create_profile(user_name) do
    case ldap_connect() do
      {:ok, conn} ->
        try do
          case ldap_search(conn, user_name) do
            {:ok, []} ->
              Logger.info("User not found while searching user...")
              {:error, :user_not_found}
            {:ok, [entry|_tail]} ->
              profile = entry
              |> build_profile
              |> Map.put(@user_name, user_name)
              |> Map.put(@user_dn, get_attribute!(entry, @distinguised_name))
              {:ok, profile}
            error ->
              Logger.info("Error while searching user... #{inspect(error)}")
              error
          end
        after
          ldap_close(conn)
        end
      error ->
        Logger.info("Error while connecting to active directory... #{inspect(error)}")
        error
    end
  end

  defp ldap_connect do
    Exldap.connect(get_ad_server(), get_ad_port(),
                   get_ad_ssl(), get_ad_user_dn(),
                   get_ad_password(), get_ad_connection_timeout())
  end

  defp ldap_close(conn) do
    Exldap.close(conn)
  end

  defp ldap_search(conn, user_name) do
    Exldap.search_field(conn, get_ad_search_path(),
                        @samaccountname, user_name)
  end

  defp build_profile(entry) do
      mapping = %{"full_name" =>  "displayName", "email" => "mail"}
      Enum.reduce(mapping, %{}, fn({k, v}, acc) ->
        attr = get_attribute!(entry, v)
        Map.put(acc, k, attr)
      end)
  end

  def get_attribute!(entry, attribute) do
    Exldap.get_attribute!(entry, attribute)
  end

  defp get_ad_server do
    Application.get_env(:td_auth, :ad)[:server]
  end

  # defp get_ad_base do
  #   Application.get_env(:td_auth, :ad)[:base]
  # end

  defp get_ad_port do
    port = Application.get_env(:td_auth, :ad)[:port]
    String.to_integer(port)
  end

  defp get_ad_ssl do
    ssl = Application.get_env(:td_auth, :ad)[:ssl]
    if ssl == "true", do: true, else: false
  end

  def get_ad_user_dn do
    Application.get_env(:td_auth, :ad)[:user_dn]
  end

  defp get_ad_password do
    Application.get_env(:td_auth, :ad)[:password]
  end

  defp get_ad_search_path do
    Application.get_env(:td_auth, :ad)[:search_path]
  end

  def get_ad_connection_timeout do
    timeout = Application.get_env(:td_auth, :ad)[:connection_timeout]
    String.to_integer(timeout)
  end

end
