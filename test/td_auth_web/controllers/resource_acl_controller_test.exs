defmodule TdAuthWeb.ResourceAclControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdCluster.TestHelpers.TdDdMock

  import Routes, only: [acl_path: 4, acl_path: 5]

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    acl_entry = insert(:acl_entry, principal_type: :user)
    {:ok, conn: conn, acl_entry: acl_entry}
  end

  describe "GET /api/acl_entries/:resource_type/:resource_id" do
    @tag authentication: [role: :admin]
    test "returns OK and body on success", %{
      conn: conn,
      swagger_schema: schema
    } do
      resource_type = "domain_or_structure_type"

      %{resource_type: ^resource_type, resource_id: resource_id} =
        insert(:acl_entry, resource_type: resource_type, principal_type: :user)

      assert %{"_embedded" => embedded, "_links" => _links} =
               conn
               |> get(acl_path(conn, :show, Inflex.pluralize(resource_type), resource_id))
               |> validate_resp_schema(schema, "ResourceAclEntriesResponse")
               |> json_response(:ok)

      assert %{"acl_entries" => [_acl_entry]} = embedded
    end

    @tag authentication: [
           role: :user,
           permissions: [:view_data_structure]
         ]
    test "list acl_entries for a structure only when user has permissions to view the structure on its domain",
         %{
           conn: conn,
           domain: %{id: allowed_domain_id}
         } do
      insert(:user)
      insert(:role)
      %{id: forbidden_domain_id} = build(:domain)

      allowed_structure_id = System.unique_integer([:positive])
      forbidden_structure_id = System.unique_integer([:positive])

      allowed_data_structure_version = %{
        data_structure_id: allowed_structure_id,
        name: "allowed_data_structure",
        data_structure: %{
          id: allowed_structure_id,
          domain_ids: [allowed_domain_id]
        }
      }

      forbidden_data_structure_version = %{
        data_structure_id: forbidden_structure_id,
        name: "forbidden_data_structure",
        data_structure: %{
          id: forbidden_structure_id,
          domain_ids: [forbidden_domain_id]
        }
      }

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        to_string(forbidden_structure_id),
        {:ok, forbidden_data_structure_version}
      )

      for _ <- 1..4 do
        TdDdMock.get_latest_structure_version(
          &Mox.expect/4,
          to_string(allowed_structure_id),
          {:ok, allowed_data_structure_version}
        )
      end

      insert(:acl_entry, resource_type: "structure", resource_id: allowed_structure_id)

      _not_allowed_acl_entry =
        insert(:acl_entry, resource_type: "structure", resource_id: forbidden_structure_id)

      assert %{"errors" => _} =
               conn
               |> get(acl_path(conn, :show, "structure", forbidden_structure_id))
               |> json_response(:forbidden)

      assert %{"_embedded" => embedded, "_links" => _links} =
               conn
               |> get(acl_path(conn, :show, "structure", allowed_structure_id))
               |> json_response(:ok)

      assert %{"acl_entries" => [_]} = embedded
    end

    @tag authentication: [role: :admin]
    test "excludes user email field", %{conn: conn, acl_entry: acl_entry} do
      %{resource_type: resource_type, resource_id: resource_id} = acl_entry

      assert %{"_embedded" => embedded} =
               conn
               |> get(acl_path(conn, :show, Inflex.pluralize(resource_type), resource_id))
               |> json_response(:ok)

      assert %{"acl_entries" => [acl_entry]} = embedded
      assert %{"principal" => principal} = acl_entry
      assert Map.keys(principal) == ["full_name", "id", "user_name"]
    end
  end

  describe "POST /api/:resource_type/:resource_id/acl_entries" do
    @tag authentication: [role: :admin]
    test "adds an entry to a resource acl", %{
      conn: conn,
      acl_entry: acl_entry,
      swagger_schema: schema
    } do
      %{resource_type: resource_type, resource_id: resource_id} = acl_entry

      %{id: user_id} = insert(:user)
      %{name: role_name} = insert(:role)
      description = "a new ACL to be added"

      params = %{
        "acl_entry" => %{
          "principal_type" => "user",
          "principal_id" => user_id,
          "role_name" => role_name,
          "description" => description
        }
      }

      conn1 =
        post(
          conn,
          acl_path(
            conn,
            :create,
            Inflex.pluralize(resource_type),
            resource_id,
            params
          )
        )

      assert response(conn1, :see_other)
      assert [location] = get_resp_header(conn1, "location")
      assert location == "/api/acl_entries/domains/#{resource_id}"

      assert %{"_embedded" => embedded, "_links" => _links} =
               conn
               |> get(location, %{})
               |> validate_resp_schema(schema, "ResourceAclEntriesResponse")
               |> json_response(:ok)

      assert %{"acl_entries" => [_acl_entry1, _acl_entry2]} = embedded
    end

    @tag authentication: [role: :user]
    test "returns forbidden when user is not authorized", %{conn: conn} do
      user = insert(:user)
      role = insert(:role)

      params = %{
        "acl_entry" => %{
          "principal_type" => "user",
          "principal_id" => user.id,
          "role_name" => role.name
        }
      }

      assert conn
             |> post(acl_path(conn, :create, "domains", "1"), params)
             |> json_response(:forbidden)
    end
  end
end
