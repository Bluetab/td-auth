defmodule TdAuthWeb.RolePermissionControllerTest do
  use TdAuthWeb.ConnCase

  @custom_prefix Application.compile_env(:td_auth, :custom_permissions_prefix)

  setup tags do
    context =
      Enum.reduce(tags, %{}, fn
        {:conn, conn}, acc ->
          Map.put(acc, :conn, put_req_header(conn, "accept", "application/json"))

        {:role, %{name: role_name, permissions: permission_names}}, acc ->
          permissions = Enum.map(permission_names, &build(:permission, name: &1))
          Map.put(acc, :role, insert(:role, name: role_name, permissions: permissions))

        _, acc ->
          acc
      end)

    {:ok, context}
  end

  describe "role permissions" do
    @tag authentication: [role: :admin]
    @tag role: %{
           name: "test",
           permissions: ["#{@custom_prefix}permission1", "#{@custom_prefix}permission2"]
         }
    test "add role role-permission relation by permission name", %{
      conn: conn,
      role: %{id: role_id}
    } do
      %{id: permission_id} = insert(:permission, name: "#{@custom_prefix}permission3")

      params = %{
        "permission_name" => "#{@custom_prefix}permission3"
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.role_permission_path(conn, :create, role_id), params)
               |> json_response(:ok)

      assert %{
               "role_id" => ^role_id,
               "permission_id" => ^permission_id
             } = data

      assert %{"data" => data} =
               conn
               |> get(Routes.role_permission_path(conn, :show, role_id))
               |> json_response(:ok)

      assert [
               %{"name" => "#{@custom_prefix}permission1"},
               %{"name" => "#{@custom_prefix}permission2"},
               %{"name" => "#{@custom_prefix}permission3"}
             ] = data
    end

    @tag authentication: [role: :admin]
    @tag role: %{
           name: "test",
           permissions: ["#{@custom_prefix}permission1", "#{@custom_prefix}permission2"]
         }
    test "add role-permission relation by permission ID", %{
      conn: conn,
      role: %{id: role_id}
    } do
      %{id: permission_id} = insert(:permission, name: "#{@custom_prefix}permission3")

      params = %{
        "permission_id" => permission_id
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.role_permission_path(conn, :create, role_id), params)
               |> json_response(:ok)

      assert %{
               "role_id" => ^role_id,
               "permission_id" => ^permission_id
             } = data

      assert %{"data" => data} =
               conn
               |> get(Routes.role_permission_path(conn, :show, role_id))
               |> json_response(:ok)

      assert [
               %{"name" => "#{@custom_prefix}permission1"},
               %{"name" => "#{@custom_prefix}permission2"},
               %{"name" => "#{@custom_prefix}permission3"}
             ] = data
    end

    @tag authentication: [role: :admin]
    @tag role: %{
           name: "test",
           permissions: ["#{@custom_prefix}permission1", "#{@custom_prefix}permission2"]
         }
    test "delete role-permission relation by permission name", %{
      conn: conn,
      role: role
    } do
      params = %{
        "permission_name" => "#{@custom_prefix}permission1"
      }

      assert conn
             |> delete(Routes.role_permission_path(conn, :delete, role.id), params)
             |> response(:no_content)

      assert %{"data" => data} =
               conn
               |> get(Routes.role_permission_path(conn, :show, role.id))
               |> json_response(:ok)

      assert [
               %{
                 "name" => "#{@custom_prefix}permission2"
               }
             ] = data
    end

    @tag authentication: [role: :admin]
    @tag role: %{
           name: "test",
           permissions: ["#{@custom_prefix}permission1", "#{@custom_prefix}permission2"]
         }
    test "delete role-permission relation by permission ID", %{
      conn: conn,
      role: role
    } do
      %{id: permission_to_delete_id} =
        Enum.find(role.permissions, &(&1.name == "#{@custom_prefix}permission1"))

      params = %{
        "permission_id" => permission_to_delete_id
      }

      assert conn
             |> delete(Routes.role_permission_path(conn, :delete, role.id), params)
             |> response(:no_content)

      assert %{"data" => data} =
               conn
               |> get(Routes.role_permission_path(conn, :show, role.id))
               |> json_response(:ok)

      assert [
               %{
                 "name" => "#{@custom_prefix}permission2"
               }
             ] = data
    end

    @tag authentication: [role: :admin]
    @tag role: %{name: "test", permissions: ["permission1", "permission2"]}
    test "list role permissions", %{conn: conn, role: role} do
      assert %{"data" => data} =
               conn
               |> get(Routes.role_permission_path(conn, :show, role.id))
               |> json_response(:ok)

      permission_names = Enum.map(data, & &1["name"])
      assert_lists_equal(permission_names, ["permission1", "permission2"])
    end

    @tag authentication: [role: :admin]
    @tag role: %{name: "test", permissions: ["permission1", "permission2"]}
    test "modify role permissions", %{conn: conn, role: role} do
      assert %{id: role_id, permissions: [%{id: permission_id1}, %{id: permission_id2}]} = role
      id_params = [%{"id" => permission_id1}, %{"id" => permission_id2}]

      assert %{"data" => data} =
               conn
               |> put(Routes.role_permission_path(conn, :update, role_id),
                 permissions: id_params
               )
               |> json_response(:ok)

      assert_lists_equal(data, id_params, &(&1["id"] == &2["id"]))
    end
  end
end
