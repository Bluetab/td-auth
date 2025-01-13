defmodule TdAuth.Factory do
  @moduledoc """
  Factory methods for tests
  """

  use ExMachina.Ecto, repo: TdAuth.Repo
  @password "secret hash"

  def user_factory do
    secret = Bcrypt.hash_pwd_salt(@password)

    %TdAuth.Accounts.User{
      user_name: sequence("username"),
      email: sequence(:email, &"username#{&1}@example.com"),
      full_name: sequence("fullname"),
      password_hash: secret,
      groups: []
    }
  end

  def group_factory do
    %TdAuth.Accounts.Group{
      name: sequence(:group, ["Europe", "Asia", "USA", "UK"]),
      description: "group_description"
    }
  end

  defp with_users(group) do
    %{group | users: [build(:user), build(:user)]}
  end

  def acl_entry_factory(attrs) do
    {principal_type, attrs} = Map.pop(attrs, :principal_type, Enum.random([:user, :group]))

    %TdAuth.Permissions.AclEntry{
      resource_type: "domain",
      resource_id: System.unique_integer([:positive]),
      role: build(:role)
    }
    |> merge_attributes(attrs)
    |> with_principal(principal_type)
  end

  defp with_principal(%{group_id: nil, user_id: nil} = acl_entry, :group) do
    group = build(:group) |> with_users()
    %{acl_entry | group: group}
  end

  defp with_principal(%{group_id: nil, user_id: nil} = acl_entry, :user) do
    %{acl_entry | user: build(:user)}
  end

  defp with_principal(acl_entry, _), do: acl_entry

  def permission_factory(attrs) do
    %TdAuth.Permissions.Permission{
      name: sequence("permission"),
      permission_group: build(:permission_group)
    }
    |> merge_attributes(attrs)
  end

  def permission_group_factory do
    %TdAuth.Permissions.PermissionGroup{
      name: sequence("permission_group")
    }
  end

  def role_factory do
    %TdAuth.Permissions.Role{
      name: sequence(:role, ["admin", "owner", "writer", "reader"]),
      is_default: false
    }
  end

  def domain_factory do
    %{
      id: System.unique_integer([:positive]),
      external_id: sequence("domain_external_id"),
      name: sequence("domain_name"),
      updated_at: DateTime.utc_now()
    }
  end
end
