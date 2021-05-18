defmodule TdAuthWeb.UserSearchControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  describe "POST /api/users/search" do
    @tag authentication: [role: :admin]
    test "will return users with essencial information", %{
      conn: conn,
      swagger_schema: schema,
      user: %{full_name: full_name}
    } do
      assert %{"data" => [user]} =
               conn
               |> post(Routes.user_search_path(conn, :create))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert %{"full_name" => ^full_name} = user
      refute Map.has_key?(user, "role")
      refute Map.has_key?(user, "user_name")
      refute Map.has_key?(user, "email")
    end

    @tag authentication: [role: :admin]
    test "will not return more results than configured max_result", %{
      conn: conn,
      swagger_schema: schema
    } do
      max_results = Application.get_env(:td_auth, TdAuthWeb.UserSearchController)[:max_results]
      more_than_max = max_results + 5
      1..more_than_max |> Enum.each(fn _ -> insert(:user) end)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == max_results
    end

    @tag authentication: [role: :admin]
    test "will filter query results", %{
      conn: conn,
      swagger_schema: schema
    } do
      insert(:user, user_name: "user.1", full_name: "aaaa Ff", email: "cccc@xxx.yy")
      insert(:user, user_name: "user.2", full_name: "bbbb", email: "dddd@xxx.yy")

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "aa f"}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "r.1"}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: ".2"}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "dd"}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "zz"}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert Enum.empty?(data)
    end
  end
end
