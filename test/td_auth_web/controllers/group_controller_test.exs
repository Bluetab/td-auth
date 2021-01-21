defmodule TdAuthWeb.GroupControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Auth.Guardian

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  describe "GET /api/groups" do
    @tag authentication: [role: :admin]
    test "admin can view groups", %{conn: conn, swagger_schema: schema} do
      assert %{"data" => []} =
               conn
               |> get(Routes.group_path(conn, :index))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)
    end

    @tag authentication: [role: :admin]
    test "lists all groups", %{conn: conn} do
      %{id: user_id, email: email, full_name: full_name, user_name: user_name} =
        user = insert(:user)

      %{id: group_id, name: name, description: description} = insert(:group, users: [user])

      assert %{
               "data" => [
                 %{
                   "description" => ^description,
                   "id" => ^group_id,
                   "name" => ^name,
                   "users" => [
                     %{
                       "email" => ^email,
                       "full_name" => ^full_name,
                       "id" => ^user_id,
                       "role" => "user",
                       "user_name" => ^user_name
                     }
                   ]
                 }
               ]
             } =
               conn
               |> get(Routes.group_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: :service]
    test "service account can view groups", %{conn: conn, swagger_schema: schema} do
      assert %{"data" => []} =
               conn
               |> get(Routes.group_path(conn, :index))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)
    end

    @tag authentication: [role: :user]
    test "user account cannot view groups", %{conn: conn, swagger_schema: schema} do
      assert %{"errors" => _} =
               conn
               |> get(Routes.group_path(conn, :index))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:forbidden)
    end

    test "user account can list all groups if he has any permission in bg", %{conn: conn} do
      {:ok, %{id: user_id, email: email, full_name: full_name, user_name: user_name} = user} =
        :user
        |> build(password: "pass000")
        |> Map.take([:user_name, :password, :email])
        |> Accounts.create_user()

      group = insert(:permission_group, name: "business_glossary_view")
      permission = insert(:permission, permission_group: group)
      role = insert(:role, permissions: [permission])

      insert(:acl_entry,
        user: user,
        role: role,
        principal_type: "user",
        resource_type: "domain",
        group: nil,
        group_id: nil
      )

      %{id: group_id, name: name, description: description} = insert(:group, users: [user])

      assert %{"token" => token} =
               conn
               |> post(Routes.session_path(conn, :create),
                 access_method: "access_method",
                 user: Map.take(user, [:user_name, :password])
               )
               |> json_response(:created)

      assert {:ok, %{"groups" => ["business_glossary_view"]}} =
               Guardian.decode_and_verify(token, %{"typ" => "access"})

      assert %{
               "data" => [
                 %{
                   "description" => ^description,
                   "id" => ^group_id,
                   "name" => ^name,
                   "users" => [
                     %{
                       "email" => ^email,
                       "full_name" => ^full_name,
                       "id" => ^user_id,
                       "role" => "user",
                       "user_name" => ^user_name
                     }
                   ]
                 }
               ]
             } =
               conn
               |> put_auth_headers(token)
               |> get(Routes.group_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "create group" do
    @tag authentication: [role: :admin]
    test "renders group when data is valid", %{conn: conn} do
      group_params = string_params_for(:group)

      assert %{"data" => %{"id" => id}} =
               conn
               |> post(Routes.group_path(conn, :create), group: group_params)
               |> json_response(:created)

      assert conn
             |> get(Routes.group_path(conn, :show, id))
             |> json_response(:ok)
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.group_path(conn, :create), group: %{"name" => nil})
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end

    @tag authentication: [role: :admin]
    test "renders errors when group is duplicated", %{conn: conn} do
      group_params = string_params_for(:group)
      post(conn, Routes.group_path(conn, :create), group: group_params)

      assert %{"errors" => %{} = errors} =
               conn
               |> post(Routes.group_path(conn, :create), group: group_params)
               |> json_response(:unprocessable_entity)

      refute errors == %{}
    end
  end

  describe "update group" do
    setup do
      [group: insert(:group)]
    end

    @tag authentication: [role: :admin]
    test "renders group when data is valid", %{conn: conn, group: %Group{id: id} = group} do
      params = string_params_for(:group)

      assert %{"data" => %{"id" => ^id}} =
               conn
               |> put(Routes.group_path(conn, :update, group), group: params)
               |> json_response(:ok)

      assert conn
             |> get(Routes.group_path(conn, :show, id))
             |> json_response(:ok)
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn, group: group} do
      assert %{"errors" => %{} = errors} =
               conn
               |> put(Routes.group_path(conn, :update, group), group: %{"name" => nil})
               |> json_response(:unprocessable_entity)

      refute errors == %{}
    end
  end

  describe "delete group" do
    @tag authentication: [role: :admin]
    test "deletes chosen group", %{conn: conn} do
      group = insert(:group)

      assert conn
             |> delete(Routes.group_path(conn, :delete, group))
             |> response(:no_content)

      assert_error_sent :not_found, fn -> get(conn, Routes.group_path(conn, :show, group)) end
    end
  end
end
