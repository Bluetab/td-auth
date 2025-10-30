defmodule TdAuthWeb.AuthProvider.DefaultProfileMappingTest do
  use ExUnit.Case, async: true

  alias TdAuthWeb.AuthProvider.DefaultProfileMapping

  import Mox

  setup :verify_on_exit!

  describe "map_profile/1" do
    test "maps profile with email and name claims" do
      claims = %{"email" => "user@example.com", "name" => "John Doe"}

      assert {:ok,
              %{user_name: "user@example.com", full_name: "John Doe", email: "user@example.com"}} =
               DefaultProfileMapping.map_profile(claims)
    end

    test "maps profile with preferred_username and name claims" do
      claims = %{"preferred_username" => "johndoe", "name" => "John Doe"}

      assert {:ok, %{user_name: "johndoe", full_name: "John Doe", email: "johndoe"}} =
               DefaultProfileMapping.map_profile(claims)
    end

    test "maps profile with unique_name and name claims" do
      claims = %{"unique_name" => "johndoe@example.com", "name" => "John Doe"}

      assert {:ok,
              %{
                user_name: "johndoe@example.com",
                full_name: "John Doe",
                email: "johndoe@example.com"
              }} =
               DefaultProfileMapping.map_profile(claims)
    end

    test "handles claims with additional fields" do
      claims = %{
        "email" => "user@example.com",
        "name" => "John Doe",
        "extra_field" => "extra_value"
      }

      assert {:ok,
              %{user_name: "user@example.com", full_name: "John Doe", email: "user@example.com"}} =
               DefaultProfileMapping.map_profile(claims)
    end
  end
end
