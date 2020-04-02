defmodule TdAuthWeb.UserPermissionView do
  use TdAuthWeb, :view
  alias TdAuthWeb.UserPermissionView

  def render("show.json", %{permission_domains: permission_domains}) do
    %{
      permission_domains:
        render_many(permission_domains, UserPermissionView, "permission_domain.json",
          as: :permission_domain
        )
    }
  end

  def render("permission_domain.json", %{
        permission_domain: %{name: permission_name, domains: domains}
      }) do
    %{
      permission: permission_name,
      domains: render_many(domains, UserPermissionView, "domain.json")
    }
  end

  def render("domain.json", %{user_permission: domain}) do
    %{id: domain.id, name: domain.name}
  end
end
