defmodule TdAuthWeb.AuthProvider.CustomProfileMapping do
  @moduledoc """
  Support customized profile mapping from authentication providers.
  """

  def map_profile(mapping, claims)

  def map_profile(mapping, %{} = claims) when is_binary(mapping) do
    case Jason.decode!(mapping) do
      {:ok, %{} = mapping} -> map_profile(mapping, claims)
      _ -> {:error, :invalid_profile_mapping}
    end
  end

  def map_profile(mapping, %{} = claims) do
    profile = Map.new(mapping, fn {k, v} -> {k, profile_mapping_value(claims, v)} end)

    {:ok, profile}
  end

  defp profile_mapping_value(profile, key) when is_binary(key), do: Map.get(profile, key)

  defp profile_mapping_value(profile, keys) when is_list(keys) do
    keys
    |> Enum.map(&Map.get(profile, &1, ""))
    |> Enum.join(" ")
  end
end
