defmodule TdAuthWeb.ResourceAclView do
  use TdAuthWeb, :view

  alias TdAuthWeb.AclEntryView

  def render("show.json", %{embedded: embedded, links: links}) do
    %{_links: links, _embedded: render_one(embedded, __MODULE__, "embedded.json", as: :embedded)}
  end

  def render("embedded.json", %{embedded: %{acl_entries: acl_entries}}) do
    acl_entries = render_many(acl_entries, AclEntryView, "resource_acl_entry.json", as: :embedded)
    %{acl_entries: acl_entries}
  end
end
