defmodule TdAuthWeb.AclEntryView do
  use TdAuthWeb, :view

  alias TdAuthWeb.GroupView
  alias TdAuthWeb.UserView

  def render("index.json", %{acl_entries: acl_entries}) do
    %{data: render_many(acl_entries, __MODULE__, "acl_entry.json")}
  end

  def render("show.json", %{acl_entry: acl_entry}) do
    %{data: render_one(acl_entry, __MODULE__, "acl_entry.json")}
  end

  def render("acl_entry.json", %{acl_entry: acl_entry}) do
    Map.take(acl_entry, [
      :description,
      :group_id,
      :id,
      :resource_id,
      :resource_type,
      :role_id,
      :user_id
    ])
  end

  def render("resource_acl_entry.json", %{embedded: %{acl_entry: acl_entry, links: links}}) do
    acl_entry
    |> render_one(__MODULE__, "resource_acl_entry.json")
    |> Map.put(:_links, links)
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
    |> resource_acl_entry()
    |> Map.put(:_actions, actions)
  end

  defp resource_acl_entry(
         %{
           description: description,
           id: id,
           role: %{id: role_id, name: role_name}
         } = acl_entry
       ) do
    %{
      description: description,
      acl_entry_id: id,
      principal_type: principal_type(acl_entry),
      principal: render_principal(acl_entry),
      role_id: role_id,
      role_name: role_name
    }
  end

  defp principal_type(%{user_id: user_id}) when not is_nil(user_id), do: "user"
  defp principal_type(%{group_id: group_id}) when not is_nil(group_id), do: "group"

  defp render_principal(%{group: group}) when not is_nil(group) do
    render_one(group, GroupView, "group.json")
  end

  defp render_principal(%{user: user}) when not is_nil(user) do
    user
    |> Map.drop([:email, :role])
    |> render_one(UserView, "user_embedded.json")
  end
end
