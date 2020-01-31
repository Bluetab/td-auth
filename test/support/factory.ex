defmodule TdAuth.Factory do
  @moduledoc """
  Factory methods for tests
  """

  use ExMachina.Ecto, repo: TdAuth.Repo

  def user_factory do
    %TdAuth.Accounts.User{
      #id: 0,
      user_name: "bufoncillo",
      email: "bufoncillo@truedat.io",
      full_name: "Bufon Cillo",
      is_admin: false,
      groups: []
    }
  end

  def group_factory do
    %TdAuth.Accounts.Group{
      id: 0,
      name: "group name"
    }
  end

  def acl_entry_factory do
    %TdAuth.Permissions.AclEntry {
      principal_id: nil,
      principal_type: nil,
      resource_id: nil,
      resource_type: nil,
      role: nil
    }
  end

  def acl_entry_resource_factory do
    %TdAuth.Permissions.AclEntry {
      principal_id: nil,
      principal_type: "user",
      resource_id: nil,
      resource_type: "domain",
      role: nil
    }
  end

  def permission_factory do
    %TdAuth.Permissions.Permission {
      name: "custom_permission",
      permission_group: build(:permission_group)
    }
  end

  def permission_group_factory do
    %TdAuth.Permissions.PermissionGroup {
      name: "custom_group"
    }
  end

  def role_factory do
    %TdAuth.Permissions.Role {
      name: "custom_role",
      is_default: false
    }
  end

end
