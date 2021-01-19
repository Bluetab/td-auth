defmodule TdAuthWeb.GroupControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil}
  @create_user_attrs %{
    password: "some password_hash",
    user_name: "some user_name",
    email: "some@email.com"
  }

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  def fixture(:group) do
    {:ok, group} = Accounts.create_group(@create_attrs)
    group
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_user_attrs)
    user
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

    @tag authentication: [role: :service]
    test "service account can view groups", %{conn: conn} do
      assert %{"data" => []} =
               conn
               |> get(Routes.group_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: :user]
    test "user account cannot view groups", %{conn: conn} do
      assert %{"errors" => _} =
               conn
               |> get(Routes.group_path(conn, :index))
               |> json_response(:forbidden)
    end
  end

  describe "create group" do
    @tag authentication: [role: :admin]
    test "renders group when data is valid", %{conn: conn} do
      assert %{"data" => %{"id" => id}} =
               conn
               |> post(Routes.group_path(conn, :create), group: @create_attrs)
               |> json_response(:created)

      assert conn
             |> get(Routes.group_path(conn, :show, id))
             |> json_response(:ok)
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.group_path(conn, :create), group: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end

    @tag authentication: [role: :admin]
    test "renders errors when group is duplicated", %{conn: conn} do
      post(conn, Routes.group_path(conn, :create), group: @create_attrs)

      assert %{"errors" => %{} = errors} =
               conn
               |> post(Routes.group_path(conn, :create), group: @create_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end
  end

  describe "update group" do
    setup [:create_group]

    @tag authentication: [role: :admin]
    test "renders group when data is valid", %{conn: conn, group: %Group{id: id} = group} do
      assert %{"data" => %{"id" => ^id}} =
               conn
               |> put(Routes.group_path(conn, :update, group), group: @update_attrs)
               |> json_response(:ok)

      assert conn
             |> get(Routes.group_path(conn, :show, id))
             |> json_response(:ok)
    end

    @tag authentication: [role: :admin]
    test "renders errors when data is invalid", %{conn: conn, group: group} do
      assert %{"errors" => %{} = errors} =
               conn
               |> put(Routes.group_path(conn, :update, group), group: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
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

  defp create_group(_) do
    group = fixture(:group)
    {:ok, group: group}
  end
end
