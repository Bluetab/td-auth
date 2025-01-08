defmodule TdAuthWeb.RoleControllerTest do
  use TdAuthWeb.ConnCase

  setup do
    [role: insert(:role)]
  end

  describe "GET /api/roles" do
    @tag authentication: [role: :admin]
    test "admin can view roles", %{conn: conn} do
      assert %{"data" => [_role]} =
               conn
               |> get(Routes.role_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: :service]
    test "service account can view roles", %{conn: conn} do
      assert %{"data" => [_role]} =
               conn
               |> get(Routes.role_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: :user]
    test "user account can view roles", %{conn: conn} do
      assert %{"data" => [_role]} =
               conn
               |> get(Routes.role_path(conn, :index))
               |> json_response(:ok)
    end

    test "non-authenticated requests cannot view roles", %{conn: conn} do
      assert %{"message" => "unauthorized"} =
               conn
               |> get(Routes.role_path(conn, :index))
               |> json_response(:unauthorized)
    end
  end

  describe "create role" do
    @tag authentication: [role: :admin]
    test "renders role when data is valid", %{conn: conn} do
      assert %{"data" => data} =
               conn
               |> post(Routes.role_path(conn, :create), role: %{name: "valid role"})
               |> json_response(:created)

      assert %{"id" => _, "is_default" => false, "name" => "valid role"} = data
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.role_path(conn, :create), role: %{}
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update role" do
    @tag authentication: [role: :admin]
    test "renders role when data is valid", %{
      conn: conn
    } do
      name = "updated name"
      %{id: id} = role = insert(:role)

      assert %{"data" => data} =
               conn
               |> put(Routes.role_path(conn, :update, role),
                 role: %{name: name, is_default: true}
               )
               |> json_response(:ok)

      assert %{"id" => ^id, "is_default" => true, "name" => ^name} = data
    end

    @tag authentication: [role: :admin]
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
    @tag authentication: [role: :admin]
    test "deletes chosen role", %{conn: conn, role: role} do
      assert conn
             |> delete(Routes.role_path(conn, :delete, role))
             |> response(:no_content)

      assert_error_sent :not_found, fn -> get(conn, Routes.role_path(conn, :show, role)) end
    end
  end
end
