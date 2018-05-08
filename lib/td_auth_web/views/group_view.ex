defmodule TdAuthWeb.GroupView do
  use TdAuthWeb, :view
  alias TdAuthWeb.GroupView

  def render("index.json", %{groups: groups}) do
    %{data: render_many(groups, GroupView, "group.json")}
  end

  def render("show.json", %{group: group}) do
    %{data: render_one(group, GroupView, "group.json")}
  end

  def render("group.json", %{group: group}) do
    %{id: group.id,
      name: group.name}
  end

  def render("name.json", %{group: group}) do
    group.name
  end

end
