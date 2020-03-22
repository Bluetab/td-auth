defmodule TdAuthWeb.AclEntryControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Permissions

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    start_supervised!(TdAuth.Permissions.AclLoader)
    :ok
  end

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    acl_entry = insert(:acl_entry, principal_type: :user)
    {:ok, conn: conn, acl_entry: acl_entry}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all acl_entries", %{conn: conn} do
      conn = get(conn, Routes.acl_entry_path(conn, :index))
      assert [_acl_entry] = json_response(conn, 200)["data"]
    end
  end

  describe "create acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema} do
      %{id: user_id} = insert(:user)
      %{id: role_id} = insert(:role)
      resource_id = :rand.uniform(100_000)
      description = "a new ACL to be created"

      acl_entry_attrs = %{
        user_id: user_id,
        role_id: role_id,
        resource_type: "domain",
        resource_id: resource_id,
        description: description
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.acl_entry_path(conn, :create), acl_entry: acl_entry_attrs)
               |> validate_resp_schema(schema, "AclEntryResponse")
               |> json_response(:created)

      assert %{
               "id" => _,
               "group_id" => nil,
               "user_id" => ^user_id,
               "resource_id" => ^resource_id,
               "resource_type" => "domain",
               "role_id" => ^role_id,
               "description" => ^description
             } = data
    end

    @tag :admin_authenticated
    test "renders error for duplicated acl_entry", %{conn: conn, acl_entry: acl_entry} do
      params = Map.take(acl_entry, [:user_id, :group_id, :resource_type, :resource_id, :role_id])

      assert %{"errors" => errors} =
               conn
               |> post(Routes.acl_entry_path(conn, :create), acl_entry: params)
               |> json_response(:unprocessable_entity)
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      params = %{"acl_entry" => %{"foo" => "bar"}}

      assert %{"errors" => errors} =
               conn
               |> post(Routes.acl_entry_path(conn, :create), params)
               |> json_response(:unprocessable_entity)
    end
  end

  describe "create or update acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when creating a new acl", %{conn: conn, swagger_schema: schema} do
      user = insert(:user)
      role = insert(:role)

      acl_entry_attrs =
        build(:acl_entry, user_id: user.id, resource_type: "domain", resource_id: user.id)

      acl_entry_attrs =
        acl_entry_attrs |> Map.from_struct() |> Map.put(:description, "description")

      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role.name)
      conn = post conn, Routes.acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => id, "description" => description} = json_response(conn, :created)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get(conn, Routes.acl_entry_path(conn, :show, id))
      validate_resp_schema(conn, schema, "AclEntryResponse")

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "user_id" => user.id,
               "group_id" => nil,
               "resource_id" => user.id,
               "resource_type" => "domain",
               "role_id" => role.id,
               "description" => description
             }
    end

    @tag :authenticated_user
    test "renders error when creating a new acl without permission", %{conn: conn, user: user} do
      role = insert(:role)

      params = %{
        "acl_entry" => %{
          "user_id" => user.id,
          "resource_id" => "1",
          "resource_type" => "domain",
          "role_name" => role.name,
          "description" => "description"
        }
      }

      assert conn
             |> post(Routes.acl_entry_path(conn, :create_or_update), params)
             |> json_response(:forbidden)
    end

    @tag :admin_authenticated
    test "updates acl when non admin user has permission", %{} do
      user = insert(:user, user_name: "user1")
      user2 = insert(:user, user_name: "user2")
      insert(:role, name: "role1")
      insert(:role, name: "role2")
      domain_id = "123"

      {:ok, %{conn: conn, claims: %{"jti" => jti, "exp" => exp}}} = create_user_auth_conn(user)

      acl_entries = [
        %{
          permissions: ["create_acl_entry", "update_acl_entry"],
          resource_id: domain_id,
          resource_type: "domain"
        }
      ]

      Permissions.cache_session_permissions(acl_entries, jti, exp)

      # create acl entry with valid user
      acl_entry_attrs = %{
        user_id: user2.id,
        resource_id: domain_id,
        resource_type: "domain",
        role_name: "role1",
        description: "description"
      }

      resp = post conn, Routes.acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert json_response(resp, :created)

      # update acl entry with valid user
      acl_entry_attrs = %{
        user_id: user2.id,
        resource_id: domain_id,
        resource_type: "domain",
        role_name: "role2",
        description: "description"
      }

      resp = post conn, Routes.acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert json_response(resp, 200)
    end

    @tag :admin_authenticated
    test "renders acl_entry when updating an existing acl", %{conn: conn, swagger_schema: schema} do
      role = insert(:role)

      %{id: id, resource_id: resource_id, group_id: group_id, user_id: user_id} =
        insert(:acl_entry)

      params = %{
        "acl_entry" => %{
          "description" => "description",
          "role_name" => role.name,
          "resource_type" => "domain",
          "resource_id" => resource_id
        }
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.acl_entry_path(conn, :create_or_update), params)
               |> validate_resp_schema(schema, "AclEntryResponse")
               |> json_response(:ok)

      assert data["description"] == "description"
      assert data["group_id"] == group_id
      assert data["id"] == id
      assert data["resource_id"] == resource_id
      assert data["resource_type"] == "domain"
      assert data["role_id"] == role.id
      assert data["user_id"] == user_id
    end
  end

  describe "update acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      acl_entry:
        %{id: id, role_id: role_id, resource_id: resource_id, resource_type: resource_type} =
          acl_entry
    } do
      %{id: group_id} = insert(:group)
      params = %{"acl_entry" => %{"group_id" => group_id, "description" => "desc2"}}

      assert %{"data" => data} =
               conn
               |> put(Routes.acl_entry_path(conn, :update, acl_entry), params)
               |> validate_resp_schema(schema, "AclEntryResponse")
               |> json_response(:ok)

      assert %{
               "description" => "desc2",
               "group_id" => ^group_id,
               "id" => ^id,
               "resource_id" => ^resource_id,
               "resource_type" => ^resource_type,
               "role_id" => ^role_id,
               "user_id" => nil
             } = data
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, acl_entry: acl_entry} do
      assert %{"errors" => errors} =
               conn
               |> put(Routes.acl_entry_path(conn, :update, acl_entry), acl_entry: %{role_id: nil})
               |> json_response(:unprocessable_entity)
    end
  end

  describe "delete acl_entry" do
    @tag :admin_authenticated
    test "deletes chosen acl_entry", %{conn: conn, acl_entry: acl_entry} do
      assert conn
             |> delete(Routes.acl_entry_path(conn, :delete, acl_entry))
             |> response(:no_content)

      assert_error_sent :not_found, fn ->
        get(conn, Routes.acl_entry_path(conn, :show, acl_entry))
      end
    end
  end
end
