defmodule TdAuth.Auth.AccessTokenTest do
  use TdAuth.DataCase

  alias TdAuth.Auth.AccessToken
  alias TdAuth.Auth.Claims
  alias TdAuth.CacheHelpers
  alias TdAuth.Permissions

  describe "AccessToken.encode_and_sign/2" do
    test "generates a verifiable and validatable signed token" do
      assert {:ok, %{} = claims} = AccessToken.generate_claims(%{"foo" => "bar"})

      assert %{
               "aud" => "truedat",
               "exp" => exp,
               "foo" => "bar",
               "iat" => iat,
               "iss" => "tdauth",
               "jti" => _,
               "nbf" => nbf
             } = claims

      assert {:ok, jwt, ^claims} = AccessToken.encode_and_sign(claims)
      assert {:ok, ^claims} = AccessToken.verify(jwt)
      assert {:ok, ^claims} = AccessToken.validate(claims)
      assert exp == iat + AccessToken.expiry()
      assert nbf == iat
    end
  end

  describe "AccessToken.new/2" do
    setup :seed_permissions

    test "builds claims with entitlements, groups and amr" do
      permissions_count = 5
      %{id: domain_id} = CacheHelpers.put_domain()
      permissions = Permissions.list_permissions() |> Enum.take_random(permissions_count)
      role = insert(:role, is_default: true, permissions: permissions)

      %{user: user} =
        insert(:acl_entry, principal_type: :user, role: role, resource_id: domain_id)

      assert {:ok, %{token: _token, claims: claims, permissions: user_permissions}} =
               AccessToken.new(user, "pwd")

      assert %{"amr" => ["pwd"], "entitlements" => ["p"], "groups" => groups} = claims
      assert length(groups) > 0
      assert Enum.count(user_permissions["domain"]) == permissions_count
    end
  end

  describe "AccessToken.resource_from_claims/1" do
    setup :seed_permissions

    test "returns a Claims struct with jti, user_id, user_name and role" do
      %{id: user_id, user_name: user_name} = user = insert(:user)
      claims = %{"jti" => "jti", "sub" => Jason.encode!(user), "role" => "test_role"}

      assert AccessToken.resource_from_claims(claims) ==
               {:ok,
                %Claims{jti: "jti", role: "test_role", user_id: user_id, user_name: user_name}}
    end
  end

  defp seed_permissions(_context) do
    Permissions.Seeds.run(nil)
  end
end
