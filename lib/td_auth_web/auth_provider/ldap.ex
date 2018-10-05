defmodule TdAuthWeb.AuthProvider.Ldap do
  @moduledoc false

  alias Gettext.Interpolation
  alias Poison, as: JSON

  def authenticate(user_name, password) do
    with {:ok, ldap_conn} <- Exldap.open,
         {:ok} <- ldap_authenticate(ldap_conn, user_name, password) do
         create_profile(ldap_conn, user_name)
    else
      error -> error
    end
  end

  defp ldap_authenticate(ldap_conn, user_name, password) do
    bind_pattern = get_ldap_bind_pattern()
    {:ok, bind} = bind_pattern
    |> Interpolation.to_interpolatable
    |> Interpolation.interpolate(%{user_name: user_name})
    case Exldap.verify_credentials(ldap_conn, bind, password) do
      :ok -> {:ok}
      error -> error
    end
  end

  defp create_profile(ldap_conn, user_name) do
    search_path  = get_ldap_search_path()
    search_field = get_ldap_search_field()
    case Exldap.search_field(ldap_conn, search_path, search_field, user_name) do
      {:ok, search_results} ->
        entry = Enum.at(search_results, 0)
        mapping = get_ldap_profile_mapping()
        profile = Enum.reduce(mapping, %{}, fn({k, v}, acc) ->
          attr = Exldap.search_attributes(entry, v)
          Map.put(acc, k, attr)
        end)
        {:ok, profile}
      error -> error
    end
  end

  defp get_ldap_profile_mapping do
    ldap_config = Application.get_env(:td_auth, :ldap)
    JSON.decode!(ldap_config[:profile_mapping])
  end

  defp get_ldap_bind_pattern do
    ldap_config = Application.get_env(:td_auth, :ldap)
    ldap_config[:bind_pattern]
  end

  defp get_ldap_search_path do
    ldap_config = Application.get_env(:td_auth, :ldap)
    ldap_config[:search_path]
  end

  defp get_ldap_search_field do
    ldap_config = Application.get_env(:td_auth, :ldap)
    ldap_config[:search_field]
  end

end
