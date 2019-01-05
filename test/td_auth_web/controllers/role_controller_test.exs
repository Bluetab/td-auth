defmodule TdAuthWeb.RoleControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Permissions.Role

  @create_attrs %{name: "some name", is_default: false}
  @update_attrs %{name: "some updated name", is_default: false}
  @invalid_attrs %{name: nil, is_default: nil}

  def fixture(:role) do
    {:ok, role} = Role.create_role(@create_attrs)
    role
  end

  defp to_string_keys(attrs) do
    for {k, v} <- attrs, into: %{}, do: {Atom.to_string(k), v}
  end

  setup_all do
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_role]

    @tag :admin_authenticated
    test "lists all roles", %{conn: conn, swagger_schema: schema} do
      conn = get conn, Routes.role_path(conn, :index)
      validate_resp_schema(conn, schema, "RolesResponse")
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "create role" do
    @tag :admin_authenticated
    test "renders role when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, Routes.role_path(conn, :create), role: @create_attrs
      validate_resp_schema(conn, schema, "RoleResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, Routes.role_path(conn, :show, id)
      validate_resp_schema(conn, schema, "RoleResponse")
      assert json_response(conn, 200)["data"] ==
        to_string_keys(Map.merge(%{id: id}, @create_attrs))
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.role_path(conn, :create), role: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update role" do
    setup [:create_role]

    @tag :admin_authenticated
    test "renders role when data is valid", %{conn: conn, swagger_schema: schema, role: %Role{id: id} = role} do
      conn = put conn, Routes.role_path(conn, :update, role), role: @update_attrs
      validate_resp_schema(conn, schema, "RoleResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, Routes.role_path(conn, :show, id)
      validate_resp_schema(conn, schema, "RoleResponse")
      assert json_response(conn, 200)["data"] ==
        to_string_keys(Map.merge(%{id: id}, @update_attrs))
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, role: role} do
      conn = put conn, Routes.role_path(conn, :update, role), role: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete role" do
    setup [:create_role]

    @tag :admin_authenticated
    test "deletes chosen role", %{conn: conn, role: role} do
      conn = delete conn, Routes.role_path(conn, :delete, role)
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, Routes.role_path(conn, :show, role)
      end
    end
  end

  defp create_role(_) do
    role = fixture(:role)
    {:ok, role: role}
  end
end
