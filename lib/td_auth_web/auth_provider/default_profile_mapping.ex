defmodule TdAuthWeb.AuthProvider.DefaultProfileMapping do
  @moduledoc """
  Default profile mapping for authentication providers.
  """

  require Logger

  # Create profile from email and name claims
  def map_profile(%{"email" => email, "name" => full_name} = _claims) do
    {:ok, %{user_name: email, full_name: full_name, email: email}}
  end

  # Create profile from name and preferred_username claims (Azure AD v2.0 ID Token)
  def map_profile(%{"preferred_username" => username, "name" => full_name}) do
    {:ok, %{user_name: username, full_name: full_name, email: username}}
  end

  # Create profile from name and unique_name claims (Azure AD v1.0 ID Token)
  def map_profile(%{"unique_name" => unique_name, "name" => full_name}) do
    {:ok, %{user_name: unique_name, full_name: full_name, email: unique_name}}
  end

  # Logs a warning if no mapping is defined for the claims
  def map_profile(claims) do
    Logger.warn("No mapping defined for claims #{inspect(claims)}")
    {:error}
  end
end
