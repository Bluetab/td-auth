defmodule TdAuthWeb.AuthProvider.CustomProfileMappingTest do
  use ExUnit.Case

  alias TdAuthWeb.AuthProvider.CustomProfileMapping

  describe "CustomProfileMapping.map_profile/2" do
    test "maps claims to a user profile" do
      mapping = %{user_name: "nickname", full_name: ["name", "family_name"], email: "email"}

      claims = %{
        "nickname" => "foo",
        "name" => "pepe",
        "family_name" => "perez",
        "email" => "foo@example.com"
      }

      assert {:ok, profile} = CustomProfileMapping.map_profile(mapping, claims)
      assert profile == %{full_name: "pepe perez", user_name: "foo", email: "foo@example.com"}
    end

    test "ignores missing values" do
      mapping = %{user_name: "nickname", full_name: ["name", "family_name"], email: "email"}
      claims = %{"nickname" => "foo", "name" => "pepe", "family_name" => "perez"}
      assert {:ok, profile} = CustomProfileMapping.map_profile(mapping, claims)
      refute Map.has_key?(profile, :email)
    end
  end
end
