defmodule TdAuthWeb.ResourceAclController do
  use TdAuthWeb, :controller

  import Canada, only: [can?: 2]

  alias TdAuth.Permissions.AclEntries
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Roles
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

  swagger_path :update do
    description("Creates or Updates an Acl Entry associated with a resources")
    produces("application/json")

    parameters do
      resource_type(:path, :string, "Resource type")
      resource_id(:path, :integer, "Resource id")
      acl_entry(:body, Schema.ref(:AclEntryCreateOrUpdate), "Acl entry create or update attrs")
    end

    response(303, "See Other")
  end

  def update(
        conn,
        %{
          "resource_type" => resource_type,
          "resource_id" => resource_id,
          "acl_entry" => acl_entry_params
        } = params
      ) do
    current_resource = conn.assigns[:current_resource]
    # TODO
    acl_entry_params = normalize_params(acl_entry_params, params)
    acl_resource = Map.take(acl_entry_params, [:resource_type, :resource_id])

    with {:can, true} <- {:can, can?(current_resource, create(acl_resource))},
         {:ok, %AclEntry{}} <- AclEntries.create_or_update(acl_entry_params) do
      conn
      |> put_resp_header("location", resource_acl_path(resource_type, resource_id))
      |> send_resp(:see_other, "")
    end
  end

  def update(
        conn,
        %{
          "resource_type" => resource_type,
          "resource_id" => resource_id,
          "acl_entries" => acl_entries
        } = params
      )
      when is_list(acl_entries) do
    # TODO
    current_resource = conn.assigns[:current_resource]
    acl_entries = normalize_params(acl_entries, params)
    acl_resource = get_resource(acl_entries)

    with {:can, true} <- {:can, can?(current_resource, create(acl_resource))},
         {:ok, _} <- AclEntries.update(acl_entries) do
      conn
      |> put_resp_header("location", resource_acl_path(resource_type, resource_id))
      |> send_resp(:see_other, "")
    end
  end

  defp normalize_params(entries, params) when is_list(entries) do
    Enum.map(entries, &normalize_params(&1, params))
  end

  defp normalize_params(entry, %{"resource_type" => resource_type, "resource_id" => resource_id}) do
    entry
    |> Map.put("resource_type", resource_type)
    |> Map.put("resource_id", resource_id)
    |> put_principal_id()
    |> put_role_id()
    |> AclEntry.changes()
    |> Map.put_new(:description, nil)
  end

  defp get_resource([head | _]) do
    Map.take(head, [:resource_type, :resource_id])
  end

  defp get_resource([]), do: Map.new()

  defp put_role_id(%{"role_name" => role_name} = params) do
    case Roles.get_by(name: role_name) do
      %{id: role_id} -> Map.put(params, "role_id", role_id)
      _nil -> params
    end
  end

  defp put_role_id(params), do: params

  defp put_principal_id(%{"principal_type" => "user", "principal_id" => user_id} = params) do
    Map.put_new(params, "user_id", user_id)
  end

  defp put_principal_id(%{"principal_type" => "group", "principal_id" => group_id} = params) do
    Map.put_new(params, "group_id", group_id)
  end

  defp put_principal_id(params), do: params

  defp with_links(
         current_resource,
         %{resource_type: resource_type, resource_id: resource_id} = acl_resource,
         acl_entries
       ) do
    self = %{
      href: resource_acl_path(resource_type, resource_id),
      methods: methods(current_resource, acl_resource)
    }

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
    Routes.resource_acl_path(Endpoint, :show, Inflex.pluralize(resource_type), resource_id)
  end

  defp acl_entry_path(acl_entry) do
    Routes.acl_entry_path(Endpoint, :show, acl_entry)
  end
end
