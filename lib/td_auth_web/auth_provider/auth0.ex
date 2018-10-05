defmodule TdAuthWeb.AuthProvider.Auth0 do
  @moduledoc false

  alias Poison, as: JSON

  @auth_service Application.get_env(:td_auth, :auth)[:auth_service]

  def authenticate(authorization_header) do
    with {:ok, access_token} <- fetch_access_token(authorization_header),
         {:ok, profile} <- get_auth0_profile(access_token) do
           {:ok, profile}
    else
      error -> error
    end
  end

  # defp get_audience do
  #   auth = Application.get_env(:td_auth, :auth)
  #   auth[:audience]
  # end
  #
  # defp check_audience(conn) do
  #   audience = get_audience()
  #   case audience do
  #     nil -> true
  #     _ ->
  #       conn
  #       |> AuthPlug.current_claims
  #       |> Map.get("aud")
  #       |> Enum.member?(audience)
  #   end
  # end

  # defp fetch_access_token(conn) do
  #   case check_audience(conn) do
  #     true ->
  #        {:ok, AuthPlug.current_token(conn)}
  #     false ->
  #       Logger.info "Unable to validate token audience"
  #       {:missing_audience}
  #   end
  # end

  defp fetch_access_token(authorization_header) do
    fetch_access_token_from_header(authorization_header)
  end

  defp fetch_access_token_from_header([]), do: {:error, :no_access_token_found}

  defp fetch_access_token_from_header([token | tail]) do
    trimmed_token = String.trim(token)

    case Regex.run(~r/^Bearer (.*)$/, trimmed_token) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> fetch_access_token_from_header(tail)
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

    {status_code, user_info} = @auth_service.get_user_info(get_auth0_profile_path(), headers)

    case status_code do
      200 ->
        profile = user_info |> JSON.decode!()
        mapping = get_auth0_profile_mapping()
        profile = Enum.reduce(mapping, %{}, fn({k, v}, acc) ->
          attr = Map.get(profile, v, nil)
          Map.put(acc, k, attr)
        end)
        {:ok, profile}
      _ -> {:error, :unable_to_get_user_profile}
    end
  end

end
