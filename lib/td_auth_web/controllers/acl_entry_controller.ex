defmodule TdAuthWeb.AclEntryController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias Inflex
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry

  action_fallback(TdAuthWeb.FallbackController)

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(AclEntry))},
         acl_entries <- AclEntries.list_acl_entries() do
      render(conn, "index.json", acl_entries: acl_entries)
    end
  end

  def create(conn, %{"acl_entry" => acl_entry_params}) do
    acl_entry = AclEntry.changes(acl_entry_params)
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, create(acl_entry))},
         {:ok, %AclEntry{} = acl_entry} <- AclEntries.create_acl_entry(acl_entry_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.acl_entry_path(conn, :show, acl_entry))
      |> render("show.json", acl_entry: acl_entry)
    end
  end

  def show(conn, %{"id" => id}) do
    acl_entry = AclEntries.get_acl_entry!(id)
    render(conn, "show.json", acl_entry: acl_entry)
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with %AclEntry{} = acl_entry <- AclEntries.get_acl_entry!(id),
         {:can, true} <- {:can, can?(claims, delete(acl_entry))},
         {:ok, %AclEntry{}} <- AclEntries.delete_acl_entry(acl_entry) do
      send_resp(conn, :no_content, "")
    end
  end

  def update(conn, %{"id" => id, "acl_entry" => acl_entry_params}) do
    claims = conn.assigns[:current_resource]
    acl_entry = AclEntries.get_acl_entry!(id)

    with {:can, true} <- {:can, can?(claims, update(acl_entry))},
         {:ok, %AclEntry{} = acl_entry} <-
           AclEntries.update_acl_entry(acl_entry, acl_entry_params) do
      render(conn, "show.json", acl_entry: acl_entry)
    end
  end
end
