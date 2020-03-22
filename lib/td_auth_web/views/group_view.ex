defmodule TdAuthWeb.GroupView do
  use TdAuthWeb, :view
  alias TdAuthWeb.GroupView
  alias TdAuthWeb.UserView

  def render("index.json", %{groups: groups}) do
    %{data: render_many(groups, GroupView, "group.json")}
  end

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user_embedded.json")}
  end

  def render("show.json", %{group: group}) do
    %{data: render_one(group, GroupView, "group.json")}
  end

  def render("group.json", %{group: %{users: users} = group}) when is_list(users) do
    users = render_many(users, UserView, "user_embedded.json")
    %{id: group.id, name: group.name, description: group.description, users: users}
  end

  def render("group.json", %{group: group}) do
    %{id: group.id, name: group.name, description: group.description}
  end

  def render("name.json", %{group: group}) do
    group.name
  end

end
