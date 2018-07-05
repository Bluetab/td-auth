defmodule TdAuthWeb.AclEntryView do
  use TdAuthWeb, :view
  use TdHypermedia, :view
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Repo
  alias TdAuthWeb.AclEntryView
  alias TdAuthWeb.GroupView
  alias TdAuthWeb.UserView

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

  def render("resource_acl_entries.json", %{acl_entries: acl_entries, hypermedia: hypermedia}) do
    render_many_hypermedia(acl_entries, hypermedia, AclEntryView, "resource_acl_entry.json")
  end

  def render("resource_acl_entry.json", %{acl_entry: acl_entry}) do
    %{
      principal: render_principal(acl_entry.principal_type, acl_entry.principal_id),
      principal_type: acl_entry.principal_type,
      role_name: acl_entry.role.name,
      role_id: acl_entry.role.id,
      acl_entry_id: acl_entry.id
    }
  end

  def render_principal("group", group_id) do
    group = Repo.get_by(Group, id: group_id)
    render_one(group, GroupView, "group.json")
  end

  def render_principal("user", user_id) do
    user = Repo.get_by(User, id: user_id)
    render_one(user, UserView, "user_embedded.json")
  end

end
