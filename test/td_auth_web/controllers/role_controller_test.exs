defmodule TdAuthWeb.RoleControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.Permissions.Roles

  @create_attrs %{name: "some name", is_default: false}

  def fixture(:role) do
    {:ok, role} = Roles.create_role(@create_attrs)
    role
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_role]

    @tag :admin_authenticated
    test "lists all roles", %{conn: conn, swagger_schema: schema} do
      conn = get(conn, Routes.role_path(conn, :index))
      validate_resp_schema(conn, schema, "RolesResponse")
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "create role" do
    @tag :admin_authenticated
    test "renders role when data is valid", %{conn: conn, swagger_schema: schema} do
      assert %{"data" => data} =
               conn
               |> post(Routes.role_path(conn, :create), role: %{name: "valid role"})
               |> validate_resp_schema(schema, "RoleResponse")
               |> json_response(:created)

      assert %{"id" => _, "is_default" => false, "name" => "valid role"} = data
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.role_path(conn, :create), role: %{}
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update role" do
    @tag :admin_authenticated
    test "renders role when data is valid", %{
      conn: conn,
      swagger_schema: schema
    } do
      name = "updated name"
      %{id: id} = role = insert(:role)

      assert %{"data" => data} =
               conn
               |> put(Routes.role_path(conn, :update, role), role: %{name: name, is_default: true})
               |> validate_resp_schema(schema, "RoleResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "is_default" => true, "name" => ^name} = data
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      role = insert(:role)

      assert %{"errors" => errors} =
               conn
               |> put(Routes.role_path(conn, :update, role), role: %{name: nil})
               |> json_response(:unprocessable_entity)

      assert errors == %{"name" => ["can't be blank"]}
    end
  end

  describe "delete role" do
    setup [:create_role]

    @tag :admin_authenticated
    test "deletes chosen role", %{conn: conn, role: role} do
      assert conn
             |> delete(Routes.role_path(conn, :delete, role))
             |> response(:no_content)

      assert_error_sent :not_found, fn -> get(conn, Routes.role_path(conn, :show, role)) end
    end
  end

  defp create_role(_) do
    role = insert(:role)
    {:ok, role: role}
  end
end
