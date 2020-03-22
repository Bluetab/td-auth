defmodule TdAuthWeb.ResourceAclController do
  use TdAuthWeb, :controller
  use TdHypermedia, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions.AclEntries

  action_fallback(TdAuthWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.acl_entry_swagger_definitions()
  end

  swagger_path :show do
    description("Lists acl entries of a specified resource")
    produces("application/json")

    parameters do
      resource_type(:path, :string, "Resource Type", required: true)
      resource_id(:path, :string, "Resource Id", required: true)
    end

    response(200, "Ok", Schema.ref(:ResourceAclEntriesResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"resource_type" => resource_type, "resource_id" => resource_id}) do
    alias TdAuthWeb.AclEntryView

    resource_type = Inflex.singularize(resource_type)

    current_resource = conn.assigns[:current_resource]
    acl_resource = %{resource_type: resource_type, resource_id: resource_id}

    with {:can, true} <- {:can, can?(current_resource, view_acl_entries(acl_resource))},
         acl_entries <- AclEntries.list_acl_entries(acl_resource) do
      conn
      |> put_view(AclEntryView)
      |> render("resource_acl_entries.json",
        hypermedia: collection_hypermedia("acl_entry", conn, acl_entries, acl_resource),
        acl_entries: acl_entries
      )
    end
  end

  def update(conn, %{"resource_type" => resource_type, "resource_id" => resource_id}) do
    conn
    |> put_resp_header("location", resource_acl_path(conn, resource_type, resource_id))
    |> send_resp(:see_other, "")
  end

  defp resource_acl_path(conn, resource_type, resource_id) do
    conn
    |> endpoint_module()
    |> Routes.resource_acl_path(:show, resource_type, resource_id)
  end
end
