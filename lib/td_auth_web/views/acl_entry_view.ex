defmodule TdAuthWeb.AclEntryView do
  use TdAuthWeb, :view
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuthWeb.AclEntryView

  def render("index.json", %{acl_entries: acl_entries}) do
    %{data: render_many(acl_entries, AclEntryView, "acl_entry.json")}
  end

  def render("show.json", %{acl_entry: acl_entry}) do
    %{data: render_one(acl_entry, AclEntryView, "acl_entry.json")}
  end

  def render("acl_entry.json", %{acl_entry: acl_entry}) do
    %{id: acl_entry.id,
      principal_type: acl_entry.principal_type,
      principal_id: acl_entry.principal_id,
      resource_type: acl_entry.resource_type,
      resource_id: acl_entry.resource_id,
      role_id: acl_entry.role_id
    }
  end

  def render("resource_acl_entries.json", %{acl_entries: acl_entries}) do
    %{data: render_many(acl_entries, AclEntryView, "resource_acl_entry.json")}
  end

  def render("resource_acl_entry.json", %{acl_entry: acl_entry}) do
    %{
      principal: render_principal(acl_entry.principal),
      principal_type: acl_entry.principal_type,
      role_name: acl_entry.role_name,
      role_id: acl_entry.role_id,
      acl_entry_id: acl_entry.acl_entry_id
    }
  end

  def render_principal(%Group{} = group) do
    render_one(group, GroupView, "group.json")
  end

  def render_principal(%User{} = user) do
    render_one(user, UserView, "user.json")
  end

end
