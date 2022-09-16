defmodule TdAuthWeb.UserSearchControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdAuth.CacheHelpers

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

    @tag authentication: [role: :admin]
    test "will return users using permission filter", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{id: domain_id_1} = CacheHelpers.put_domain()
      %{id: domain_id_2} = CacheHelpers.put_domain()

      %{permissions: [permission]} =
        role_1 = insert(:role, name: "role1", permissions: [build(:permission)])

      role_2 = insert(:role, name: "role2", permissions: [permission])

      %{id: user_id_1, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      insert(:user)

      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_2)
      insert(:acl_entry, user_id: user_id_3, role: role_2)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{permission: permission.name}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [%{"id" => ^user_id_1}, %{"id" => ^user_id_2}] = data
    end

    @tag authentication: [role: :user]
    test "will return empty list using permission filter with non admin for different permission than allow_foreign_grant_request",
         %{
           conn: conn,
           swagger_schema: schema
         } do
      %{id: domain_id_1} = CacheHelpers.put_domain()
      %{id: domain_id_2} = CacheHelpers.put_domain()

      %{permissions: [permission]} =
        role_1 = insert(:role, name: "role1", permissions: [build(:permission)])

      role_2 = insert(:role, name: "role2", permissions: [permission])

      %{groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      insert(:user)

      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_2)
      insert(:acl_entry, user_id: user_id_3, role: role_2)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{permission: permission.name}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [] = data
    end

    @tag authentication: [role: :user]
    test "will return users using permission filter with non admin for permission allow_foreign_grant_request",
         %{
           conn: conn,
           swagger_schema: schema,
           claims: claims
         } do
      %{id: domain_id_1} = CacheHelpers.put_domain()

      CacheHelpers.put_session_permissions(claims, domain_id_1, [:create_foreign_grant_request])

      %{id: domain_id_2} = CacheHelpers.put_domain()

      %{permissions: [permission]} =
        role_1 =
        insert(:role,
          name: "role1",
          permissions: [build(:permission, name: "allow_foreign_grant_request")]
        )

      role_2 = insert(:role, name: "role2", permissions: [permission])

      %{id: user_id_1, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      insert(:user)

      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_2)
      insert(:acl_entry, user_id: user_id_3, role: role_2)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{permission: permission.name}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [%{"id" => ^user_id_1}] = data
    end
  end
end
