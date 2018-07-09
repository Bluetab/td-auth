defmodule TdAuthWeb.UserView do
  use TdAuthWeb, :view
  alias TdAuthWeb.GroupView
  alias TdAuthWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user} = assigns) do
    %{
      data: render_one(
        user,
        UserView,
        "user.json",
        Map.drop(assigns, [:user])
      )
    }
  end

  def render("user.json", %{user: user} = assigns) do
    %{id: user.id,
      user_name: user.user_name,
      email: user.email,
      full_name: user.full_name,
      is_admin: user.is_admin,
      groups: render_many(user.groups, GroupView, "name.json")
    } |> render_role_mappings(assigns)
  end

  def render("user_embedded.json", %{user: user}) do
    user
      |> Map.take([:id, :user_name, :email, :full_name, :is_admin])
  end

  defp render_role_mappings(user_map, %{role_mappings: role_mappings}) do
    Map.put(user_map, :role_mappings, role_mappings)
  end
  defp render_role_mappings(user_map, _), do: user_map
end
