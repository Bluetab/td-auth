defmodule TdAuth.SessionsTest do
  use TdAuth.DataCase

  alias TdAuth.CacheHelpers
  alias TdAuth.Permissions
  alias TdAuth.Sessions
  alias TdCache.Permissions, as: CachePermissions

  describe "Sessions.create/2" do
    test "Returns access token, refresh token and claims" do
      user = insert(:user)
      assert {:ok, %{token: _, refresh_token: _, claims: _}} = Sessions.create(user, "foo")
    end

    test "writes user's permissions on session Cache" do
      Permissions.Seeds.run(nil)
      permissions_count = 5
      %{id: domain_id} = CacheHelpers.put_domain()
      permissions = Permissions.list_permissions() |> Enum.take_random(permissions_count)
      role = insert(:role, is_default: true, permissions: permissions)

      %{user: user} =
        insert(:acl_entry, principal_type: :user, role: role, resource_id: domain_id)

      {:ok, %{token: _, refresh_token: _, claims: %{"jti" => jti}}} = Sessions.create(user, "foo")

      expected_permissions = Permissions.user_permissions(user)
      cache_permissions = CachePermissions.get_session_permissions(jti)

      assert expected_permissions == cache_permissions
    end
  end

  describe "Sessions.refresh/2" do
    test "exchanges an access token and refresh token for a new pair of tokens (only once)" do
      user = insert(:user)
      {:ok, %{token: token, refresh_token: refresh}} = Sessions.create(user, "foo")

      assert {:ok, %{token: token2, refresh_token: refresh2, claims: _}} =
               Sessions.refresh(refresh, token)

      assert {:error, :not_found} = Sessions.refresh(refresh, token)
      assert {:ok, %{token: _, refresh_token: _, claims: _}} = Sessions.refresh(refresh2, token2)
    end

    test "rewrites user's permissions on session Cache" do
      Permissions.Seeds.run(nil)
      permissions_count = 5
      %{id: domain_id} = CacheHelpers.put_domain()
      permissions = Permissions.list_permissions() |> Enum.take_random(permissions_count)
      role = insert(:role, is_default: true, permissions: permissions)

      %{user: user} =
        insert(:acl_entry, principal_type: :user, role: role, resource_id: domain_id)

      {:ok, %{token: token, refresh_token: refresh}} = Sessions.create(user, "foo")

      {:ok, %{token: _, refresh_token: _, claims: %{"jti" => jti}}} =
        Sessions.refresh(refresh, token)

      expected_permissions = Permissions.user_permissions(user)
      cache_permissions = CachePermissions.get_session_permissions(jti)

      assert expected_permissions == cache_permissions
    end
  end

  describe "Sessions.delete/2" do
    test "deletes sessions from cache" do
      user = insert(:user)
      {:ok, %{token: token, refresh_token: refresh}} = Sessions.create(user, "foo")
      assert Sessions.delete(refresh, token) == :ok
      assert Sessions.delete(refresh, token) == {:error, :not_found}
    end
  end
end
