defmodule TdAuthWeb.UserSearchControllerTest do
  use TdAuthWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdAuth.TestOperators

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

      assert [user_id_1, user_id_2] <|> Enum.map(data, & &1["id"])
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

    @tag authentication: [role: :user]
    test "will return users using domains filter with non admin", %{conn: conn} do
      %{id: domain_id_1} = CacheHelpers.put_domain()
      %{id: domain_id_2} = CacheHelpers.put_domain()
      %{id: domain_id_3} = CacheHelpers.put_domain()

      %{permissions: [permission]} =
        role_1 = insert(:role, name: "role1", permissions: [build(:permission)])

      role_2 = insert(:role, name: "role2", permissions: [permission])

      %{id: user_id_1, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      insert(:user)

      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_2)
      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_3)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_3)
      insert(:acl_entry, user_id: user_id_3, role: role_2)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{domains: [domain_id_2]}))
               |> json_response(:ok)

      assert [%{"id" => ^user_id_2}] = data

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{domains: [domain_id_1]}))
               |> json_response(:ok)

      assert [%{"id" => ^user_id_1}] = data

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{domains: [domain_id_3]}))
               |> json_response(:ok)

      user_ids = Enum.map(data, &Map.get(&1, "id"))
      assert Enum.count(user_ids) == 2
      assert Enum.member?(user_ids, user_id_1)
      assert Enum.member?(user_ids, user_id_2)
      refute Enum.member?(user_ids, user_id_3)
    end

    @tag authentication: [role: :user]
    test "will return users using permission filter with non admin for permission allow_foreign_grant_request filtered by domains",
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
               |> post(
                 Routes.user_search_path(conn, :create, %{
                   permission: permission.name,
                   domains: [domain_id_2]
                 })
               )
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [] = data

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.user_search_path(conn, :create, %{
                   permission: permission.name,
                   domains: [domain_id_1]
                 })
               )
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [%{"id" => ^user_id_1}] = data
    end

    @tag authentication: [role: :user]
    test "will return users using roles filter with non admin", %{conn: conn} do
      %{id: domain_id_1} = CacheHelpers.put_domain()
      %{id: domain_id_2} = CacheHelpers.put_domain()
      %{id: domain_id_3} = CacheHelpers.put_domain()

      %{permissions: [permission]} =
        %{id: role_id_1} =
        role_1 = insert(:role, name: "role1", permissions: [build(:permission)])

      %{id: role_id_2} = role_2 = insert(:role, name: "role2", permissions: [permission])

      %{id: user_id_1, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      insert(:user)

      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_2)
      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_3)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_3)
      insert(:acl_entry, user_id: user_id_3, role: role_2)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{roles: [role_id_1]}))
               |> json_response(:ok)

      assert [%{"id" => ^user_id_1}] = data

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{roles: [role_id_2]}))
               |> json_response(:ok)

      assert [user_id_2, user_id_3] <|> Enum.map(data, & &1["id"])

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.user_search_path(conn, :create, %{
                   roles: [role_id_1, role_id_2]
                 })
               )
               |> json_response(:ok)

      user_ids = Enum.map(data, &Map.get(&1, "id"))
      assert Enum.count(user_ids) == 3
      assert Enum.member?(user_ids, user_id_1)
      assert Enum.member?(user_ids, user_id_2)
      assert Enum.member?(user_ids, user_id_3)
    end

    @tag authentication: [role: :user]
    test "will return users using permission filter with non admin for permission allow_foreign_grant_request filtered by domains and roles",
         %{
           conn: conn,
           swagger_schema: schema,
           claims: claims
         } do
      %{id: domain_id_1} = CacheHelpers.put_domain()
      %{id: domain_id_2} = CacheHelpers.put_domain()
      %{id: domain_id_4} = CacheHelpers.put_domain()

      CacheHelpers.put_session_permissions(claims, %{
        "create_foreign_grant_request" => [domain_id_1, domain_id_2, domain_id_4]
      })

      %{permissions: [permission]} =
        role_1 =
        %{id: role_id_1} =
        insert(:role,
          name: "role1",
          permissions: [build(:permission, name: "allow_foreign_grant_request")]
        )

      role_2 = %{id: role_id_2} = insert(:role, name: "role2", permissions: [permission])
      role_3 = %{id: role_id_3} = insert(:role, name: "role3", permissions: [])

      %{id: user_id_1, groups: [%{id: group_id}]} = insert(:user, groups: [build(:group)])
      %{id: user_id_2} = insert(:user)
      %{id: user_id_3} = insert(:user)
      %{id: user_id_4} = insert(:user)

      insert(:acl_entry, group_id: group_id, role: role_1, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_2, role: role_2, resource_id: domain_id_2)
      insert(:acl_entry, user_id: user_id_3, role: role_3, resource_id: domain_id_2)
      insert(:acl_entry, user_id: user_id_3, role: role_3, resource_id: domain_id_1)
      insert(:acl_entry, user_id: user_id_4, role: role_2, resource_id: domain_id_4)

      # [domain_id_1], [role_1, role_2, role_3] -> user_1
      # [domain_id_1, domain_id_2], [role_2, role_3] -> user_2
      # _, _ -> [user_1, user_2, user_4]

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.user_search_path(conn, :create, %{
                   permission: permission.name,
                   domains: [domain_id_1],
                   roles: [role_id_1, role_id_2, role_id_3]
                 })
               )
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [%{"id" => ^user_id_1}] = data

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.user_search_path(conn, :create, %{
                   permission: permission.name,
                   domains: [domain_id_1, domain_id_2],
                   roles: [role_id_2, role_id_3]
                 })
               )
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [%{"id" => ^user_id_2}] = data

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{permission: permission.name}))
               |> validate_resp_schema(schema, "UsersSearchResponseData")
               |> json_response(:ok)

      assert [user_id_1, user_id_2, user_id_4] <|> Enum.map(data, & &1["id"])
    end
  end
end
