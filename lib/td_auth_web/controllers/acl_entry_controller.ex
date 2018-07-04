defmodule TdAuthWeb.AclEntryController do
  use TdAuthWeb, :controller
  use PhoenixSwagger

  alias Inflex
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdAuthWeb.ErrorView
  alias TdAuthWeb.SwaggerDefinitions
  import Canada

  action_fallback(TdAuthWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.acl_entry_swagger_definitions()
  end

  swagger_path :index do
    description("List Acl Entries")
    response(200, "OK", Schema.ref(:AclEntriesResponse))
  end

  def index(conn, _params) do
    current_resource = conn.assigns[:current_resource]
    if current_resource |> can?(view(AclEntry)) do
      acl_entries = AclEntry.list_acl_entries()
      render(conn, "index.json", acl_entries: acl_entries)
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
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
    acl_entry = %AclEntry{} |> Map.merge(to_struct(AclEntry, acl_entry_params))
    current_resource = conn.assigns[:current_resource]

    if current_resource |> can?(create(acl_entry)) do
      with {:ok, %AclEntry{} = acl_entry} <- AclEntry.create_acl_entry(acl_entry_params) do
        conn
        |> put_status(:created)
        |> put_resp_header("location", acl_entry_path(conn, :show, acl_entry))
        |> render("show.json", acl_entry: acl_entry)
      else
        _error ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, :"422.json")
      end
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end
  end

  swagger_path :create_or_update do
    description("Creates or Updates an Acl Entry")
    produces("application/json")

    parameters do
      acl_entry(:body, Schema.ref(:AclEntryCreateOrUpdate), "Acl entry create or update attrs")
    end

    response(201, "OK", Schema.ref(:AclEntryResponse))
    response(400, "Client Error")
  end

  def create_or_update(conn, %{"acl_entry" => acl_entry_params}) do
    role = Role.get_role_by_name(acl_entry_params["role_name"])
    acl_entry_params = Map.put(acl_entry_params, "role_id", role.id)
    acl_entry = %AclEntry{} |> Map.merge(to_struct(AclEntry, acl_entry_params))

    acl_query_params = %{
      principal_type: acl_entry.principal_type,
      principal_id: acl_entry.principal_id,
      resource_type: acl_entry.resource_type,
      resource_id: acl_entry.resource_id
    }

    acl_entry = AclEntry.get_acl_entry_by_principal_and_resource(acl_query_params)

    if acl_entry do
      update(conn, %{"id" => acl_entry.id, "acl_entry" => acl_entry_params})
    else
      create(conn, %{"acl_entry" => acl_entry_params})
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
    acl_entry = AclEntry.get_acl_entry!(id)
    render(conn, "show.json", acl_entry: acl_entry)
  end

  swagger_path :update do
    description("Updates Acl entry")
    produces("application/json")

    parameters do
      acl_entry(:body, Schema.ref(:AclEntryCreateUpdate), "Acl entry update attrs")
      id(:path, :integer, "Acl Entry ID", required: true)
    end

    response(200, "OK", Schema.ref(:AclEntryResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "acl_entry" => acl_entry_params}) do
    current_resource = conn.assigns[:current_resource]
    acl_entry = AclEntry.get_acl_entry!(id)

    if current_resource |> can?(update(acl_entry)) do
      with {:ok, %AclEntry{} = acl_entry} <-
             AclEntry.update_acl_entry(acl_entry, acl_entry_params) do
        render(conn, "show.json", acl_entry: acl_entry)
      else
        _error ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, :"422.json")
      end
    else
      conn
      |> put_status(:forbidden)
      |> render(ErrorView, :"403.json")
    end
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
    current_resource = conn.assigns[:current_resource]
    acl_entry = AclEntry.get_acl_entry!(id)

    if current_resource |> can?(delete(acl_entry)) do
      with {:ok, %AclEntry{}} <- AclEntry.delete_acl_entry(acl_entry) do
        send_resp(conn, :no_content, "")
      else
        _error ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, :"422.json")
      end
    else
      conn
      |> put_status(:forbidden)
      |> render(ErrorView, :"403.json")
    end
  end

  swagger_path :acl_entries do
    description("Lists acl entries of a specified resource")
    produces("application/json")

    parameters do
      resource_type(:path, :string, "Resource Type", required: true)
      resource_id(:path, :string, "Resource Id", required: true)
    end

    response(200, "Ok", Schema.ref(:ResourceAclEntriesResponse))
    response(400, "Client Error")
  end

  def acl_entries(conn, %{"resource_type" => resource_type, "resource_id" => resource_id}) do
    resource_type = Inflex.singularize(resource_type)
    acl_entries = AclEntry.list_acl_entries(%{resource_type: resource_type, resource_id: resource_id})

    render(
      conn,
      "resource_acl_entries.json",
      acl_entries: acl_entries
    )
  end

  # TODO: Why is this needed??
  defp to_struct(kind, attrs) do
    struct = struct(kind)
    Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end
  end
end
