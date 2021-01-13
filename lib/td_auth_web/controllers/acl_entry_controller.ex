defmodule TdAuthWeb.AclEntryController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias Inflex
  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry
  alias TdAuthWeb.SwaggerDefinitions

  action_fallback(TdAuthWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.acl_entry_swagger_definitions()
  end

  swagger_path :index do
    description("List Acl Entries")
    response(200, "OK", Schema.ref(:AclEntriesResponse))
  end

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, view(AclEntry))},
         acl_entries <- AclEntries.list_acl_entries() do
      render(conn, "index.json", acl_entries: acl_entries)
    end
  end

  swagger_path :create do
    description("Creates an Acl Entry")
    produces("application/json")

    parameters do
      acl_entry(:body, Schema.ref(:AclEntryCreateUpdate), "Acl entry create attrs")
    end

    response(201, "OK", Schema.ref(:AclEntryResponse))
    response(400, "Client Error")
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

  swagger_path :show do
    description("Show Acl Entry")
    produces("application/json")

    parameters do
      id(:path, :integer, "Acl Entry ID", required: true)
    end

    response(200, "OK", Schema.ref(:AclEntryResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    acl_entry = AclEntries.get_acl_entry!(id)
    render(conn, "show.json", acl_entry: acl_entry)
  end

  swagger_path :delete do
    description("Delete Acl Entry")
    produces("application/json")

    parameters do
      id(:path, :integer, "Acl entry ID", required: true)
    end

    response(204, "OK")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with %AclEntry{} = acl_entry <- AclEntries.get_acl_entry!(id),
         {:can, true} <- {:can, can?(claims, delete(acl_entry))},
         {:ok, %AclEntry{}} <- AclEntries.delete_acl_entry(acl_entry) do
      send_resp(conn, :no_content, "")
    end
  end
end
