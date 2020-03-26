defmodule TdAuthWeb.AuthProvider.Auth0 do
  @moduledoc false

  alias Jason, as: JSON

  @auth0_service Application.get_env(:td_auth, :auth)[:auth0_service]

  def authenticate(authorization_header) do
    with {:ok, access_token} <- fetch_access_token(authorization_header),
         {:ok, profile} <- get_auth0_profile(access_token) do
      {:ok, profile}
    end
  end

  defp fetch_access_token(authorization_header) do
    trimmed_token = String.trim(authorization_header)

    case Regex.run(~r/^Bearer (.*)$/, trimmed_token) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> {:error, :no_access_token_found}
    end
  end

  defp get_auth0_profile_path do
    auth = Application.get_env(:td_auth, :auth)
    "#{auth[:protocol]}://#{auth[:domain]}#{auth[:userinfo]}"
  end

  defp get_auth0_profile_mapping do
    auth = Application.get_env(:td_auth, :auth)
    auth[:profile_mapping]
  end

  defp get_auth0_profile(access_token) do
    headers = [
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8",
      Authorization: "Bearer #{access_token}"
    ]

    {status_code, user_info} = @auth0_service.get_user_info(get_auth0_profile_path(), headers)

    case status_code do
      200 ->
        profile = JSON.decode!(user_info)
        mapping = get_auth0_profile_mapping()

        profile =
          Enum.reduce(mapping, %{}, fn {k, v}, acc ->
            attr = profile_mapping_value(v, profile)
            Map.put(acc, k, attr)
          end)

        {:ok, profile}

      _ ->
        {:error, :unable_to_get_user_profile}
    end
  end

  defp profile_mapping_value(key, profile) when is_binary(key), do: Map.get(profile, key)

  defp profile_mapping_value(keys, profile) when is_list(keys) do
    keys
    |> Enum.map(&Map.get(profile, &1, ""))
    |> Enum.join(" ")
  end
end
