defmodule TdAuthWeb.GroupSearchControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  @max_results Application.compile_env(:td_auth, TdAuthWeb.GroupSearchController)[:max_results]

  describe "POST /api/groups/search" do
    @tag authentication: [role: :admin]
    test "will return groups with essencial information", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{name: name} = insert(:group)

      assert %{"data" => [group]} =
               conn
               |> post(Routes.group_search_path(conn, :create))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)

      assert %{"name" => ^name} = group
    end

    @tag authentication: [role: :admin]
    test "will not return more results than configured max_result", %{
      conn: conn,
      swagger_schema: schema
    } do
      more_than_max = @max_results + 5
      1..more_than_max |> Enum.each(fn i -> insert(:group, name: "group#{i}") end)

      assert %{"data" => data} =
               conn
               |> post(Routes.group_search_path(conn, :create))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == @max_results
    end

    @tag authentication: [role: :admin]
    test "will filter query results", %{
      conn: conn,
      swagger_schema: schema
    } do
      1..2 |> Enum.each(fn i -> insert(:group, name: "aaaa#{i}", description: "cccc") end)
      1..2 |> Enum.each(fn i -> insert(:group, name: "bbbb#{i}", description: "dddd") end)

      assert %{"data" => data} =
               conn
               |> post(Routes.group_search_path(conn, :create, %{query: "aa"}))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == 2

      assert %{"data" => data} =
               conn
               |> post(Routes.group_search_path(conn, :create, %{query: "dd"}))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == 2

      assert %{"data" => data} =
               conn
               |> post(Routes.group_search_path(conn, :create, %{query: "zz"}))
               |> validate_resp_schema(schema, "GroupsResponseData")
               |> json_response(:ok)

      assert Enum.empty?(data)
    end
  end
end
