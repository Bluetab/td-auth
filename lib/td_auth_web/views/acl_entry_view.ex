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
    %{
      id: acl_entry.id,
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
    resource_acl_entry(acl_entry)
  end

  def render("resource_user_roles.json", %{user_roles: user_roles}) do
    user_roles
    |> Enum.into([], fn {role_name, users} ->
      %{
        role_name: role_name,
        users: Enum.map(users, &Map.take(&1, [:id, :user_name, :full_name]))
      }
    end)
  end

  defp resource_acl_entry(%{"_actions" => actions} = acl_entry) do
    acl_entry
    |> Map.drop(["_actions"])
    |> resource_acl_entry
    |> Map.put(:_actions, actions)
  end

  defp resource_acl_entry(
         %{id: id, principal_type: principal_type, role: %{id: role_id, name: role_name}} =
           acl_entry
       ) do
    %{
      acl_entry_id: id,
      principal_type: principal_type,
      principal: render_principal(acl_entry),
      role_id: role_id,
      role_name: role_name
    }
  end

  defp render_principal(%{principal_type: "group", principal_id: group_id}) do
    group = Repo.get_by(Group, id: group_id)
    render_one(group, GroupView, "group.json")
  end

  defp render_principal(%{principal_type: "user", principal_id: user_id}) do
    user = Repo.get_by(User, id: user_id)
    render_one(user, UserView, "user_embedded.json")
  end
end
