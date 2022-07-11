defmodule TdAuthWeb.UserView do
  use TdAuthWeb, :view
  alias TdAuthWeb.GroupView
  alias TdAuthWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user} = assigns) do
    %{
      data:
        render_one(
          user,
          UserView,
          "user.json",
          Map.drop(assigns, [:user])
        )
    }
  end

  def render("can_init.json", %{can_init: can_init}) do
    can_init
  end

  def render("user.json", %{user: %{groups: groups} = user} = assigns) do
    groups = render_many(groups, GroupView, "name.json")

    user
    |> Map.take([:id, :user_name, :external_id, :email, :full_name, :role])
    |> Map.put(:groups, groups)
    |> render_acls(assigns)
  end

  def render("user_embedded.json", %{user: user}) do
    Map.take(user, [:id, :user_name, :email, :full_name, :role])
  end

  def render("search.json", %{users: users}) do
    %{data: render_many(users, UserView, "user_basic.json")}
  end

  def render("user_basic.json", %{user: user}) do
    Map.take(user, [:id, :full_name])
  end

  def render("user_id.json", %{user: user}) do
    %{id: user.id}
  end

  defp render_acls(user_map, %{acls: acls}) do
    Map.put(user_map, :acls, acls)
  end

  defp render_acls(user_map, _), do: user_map
end
