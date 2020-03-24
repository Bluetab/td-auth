defmodule TdAuthWeb.ResourceAclController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry
  alias TdAuthWeb.Endpoint

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
    resource_type = Inflex.singularize(resource_type)

    current_resource = conn.assigns[:current_resource]
    acl_resource = %{resource_type: resource_type, resource_id: resource_id}

    with {:can, true} <- {:can, can?(current_resource, view_acl_entries(acl_resource))},
         acl_entries <- AclEntries.list_acl_entries(acl_resource) do
      assigns = with_links(current_resource, acl_resource, acl_entries)
      render(conn, "show.json", assigns)
    end
  end

  def update(conn, %{"resource_type" => resource_type, "resource_id" => resource_id}) do
    conn
    |> put_resp_header("location", resource_acl_path(resource_type, resource_id))
    |> send_resp(:see_other, "")
  end

  defp with_links(
         current_resource,
         %{resource_type: resource_type, resource_id: resource_id} = acl_resource,
         acl_entries
       ) do
    self = %{href: resource_acl_path(resource_type, resource_id), methods: methods(current_resource, acl_resource)}
    links = %{self: self}
    embedded = %{acl_entries: Enum.map(acl_entries, &with_links(current_resource, &1))}
    %{embedded: embedded, links: links}
  end

  defp with_links(current_resource, %AclEntry{} = acl_entry) do
    self = %{href: acl_entry_path(acl_entry), methods: methods(current_resource, acl_entry)}
    links = %{self: self}

    %{acl_entry: acl_entry, links: links}
  end

  defp methods(current_resource, %AclEntry{} = acl_entry) do
    ["GET"] ++ if can?(current_resource, delete(acl_entry)), do: ["DELETE"], else: []
  end

  defp methods(current_resource, acl_resource) do
    ["GET"] ++ if can?(current_resource, create_or_update(acl_resource)), do: ["PATCH"], else: []
  end

  defp resource_acl_path(resource_type, resource_id) do
    Routes.resource_acl_path(Endpoint, :show, resource_type, resource_id)
  end

  defp acl_entry_path(acl_entry) do
    Routes.acl_entry_path(Endpoint, :show, acl_entry)
  end
end
