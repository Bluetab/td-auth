defmodule TdAuthWeb.UserView do
  use TdAuthWeb, :view
  alias TdAuthWeb.GroupView
  alias TdAuthWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      user_name: user.user_name,
      email: user.email,
      full_name: user.full_name,
      is_admin: user.is_admin,
      groups: render_many(user.groups, GroupView, "name.json")
    }
  end

  def render("user_embedded.json", %{user: user}) do
    user
      |> Map.take([:id, :user_name, :email, :full_name, :is_admin])
  end
end
