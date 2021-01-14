defmodule TdAuth.Factory do
  @moduledoc """
  Factory methods for tests
  """

  use ExMachina.Ecto, repo: TdAuth.Repo

  def user_factory do
    %TdAuth.Accounts.User{
      user_name: sequence("username"),
      email: sequence(:email, &"username#{&1}@example.com"),
      full_name: sequence("fullname"),
      password_hash: "secret hash",
      groups: []
    }
  end

  def group_factory do
    %TdAuth.Accounts.Group{
      name: sequence(:group, ["Europe", "Asia", "USA", "UK"])
    }
  end

  defp with_users(group) do
    %{group | users: [build(:user), build(:user)]}
  end

  def acl_entry_factory(attrs) do
    {principal_type, attrs} = Map.pop(attrs, :principal_type, Enum.random([:user, :group]))

    %TdAuth.Permissions.AclEntry{
      resource_type: "domain",
      resource_id: :random.uniform(1_000),
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
      id: sequence(:domain_id, & &1),
      parent_ids: [],
      name: sequence(:domain_name, &"Domain #{&1}"),
      updated_at: "2020-02-02T02:02:02.000000Z"
    }
  end
end
