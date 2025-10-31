defmodule TdAuthWeb.AuthProvider.OIDCTest do
  use ExUnit.Case

  alias TdAuthWeb.AuthProvider.OIDC
  alias TdCache.NonceCache

  setup_all do
    config = Application.get_env(:td_auth, :openid_connect_providers)
    start_supervised!({OpenIDConnect.Worker, config})
    :ok
  end

  describe "authentication_url/0" do
    test "does not include PKCE parameters if code_challenge_method is unset" do
      Application.put_env(:td_auth, TdAuthWeb.AuthProvider.OIDC, [])
      assert %{query: query} = OIDC.authentication_url("pre_login_url") |> URI.parse()
      assert %{} = params = URI.decode_query(query)
      refute Map.has_key?(params, "code_challenge")
      refute Map.has_key?(params, "code_challenge_method")
    end

    test "includes a valid, verifiable PKCE code_challenge if code_challenge_method is S256" do
      Application.put_env(:td_auth, TdAuthWeb.AuthProvider.OIDC, code_challenge_method: "S256")
      assert %{query: query} = OIDC.authentication_url("pre_login_url") |> URI.parse()

      assert %{"code_challenge" => challenge, "code_challenge_method" => "S256", "state" => state} =
               URI.decode_query(query)

      assert %{"security_token" => security_token, "url" => "pre_login_url"} =
               URI.decode_query(state)

      assert String.length(challenge) == 43

      assert {:ok, hash} = Base.url_decode64(challenge, padding: false)
      assert verifier = NonceCache.pop(security_token)
      assert hash == :crypto.hash(:sha256, verifier)
      assert String.length(verifier) == 128
    end

    test "includes groups for OIDC user" do
      allowed_groups = ["people", "Bluetaber"]

      oidc_config = [
        create_groups: true,
        group_fields: ["groups"],
        allowed_groups: allowed_groups
      ]

      Application.put_env(:td_auth, TdAuthWeb.AuthProvider.OIDC, oidc_config)

      assert {:ok, %{groups: groups}} =
               OIDC.map_profile(%{
                 "groups" => ["CTO", "manager", "Bluetaber"],
                 "name" => "John Doe",
                 "email" => "john.doe@example.com"
               })

      assert Enum.member?(groups, "Bluetaber")
      refute Enum.member?(groups, "CTO")
      refute Enum.member?(groups, "manager")
      refute Enum.member?(groups, "people")
    end
  end
end
