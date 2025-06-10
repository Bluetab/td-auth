defmodule TdAuthWeb.UserSearchControllerTest do
  use TdAuthWeb.ConnCase

  import TdAuth.TestOperators

  alias TdAuth.CacheHelpers

  @max_results Application.compile_env(:td_auth, TdAuthWeb.UserSearchController)[:max_results]

  describe "POST /api/users/search" do
    @tag authentication: [role: :admin]
    test "will return users with essencial information", %{
      conn: conn,
      user: %{full_name: full_name}
    } do
      assert %{"data" => [user]} =
               conn
               |> post(Routes.user_search_path(conn, :create))
               |> json_response(:ok)

      assert %{"full_name" => ^full_name} = user
      refute Map.has_key?(user, "role")
      refute Map.has_key?(user, "user_name")
      refute Map.has_key?(user, "email")
    end

    @tag authentication: [role: :admin]
    test "will not return more results than configured max_result", %{
      conn: conn
    } do
      more_than_max = @max_results + 5
      1..more_than_max |> Enum.each(fn _ -> insert(:user) end)

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create))
               |> json_response(:ok)

      assert Enum.count(data) == @max_results
    end

    @tag authentication: [role: :admin]
    test "will filter query results", %{
      conn: conn
    } do
      insert(:user, user_name: "user.1", full_name: "aaaa Ff", email: "cccc@xxx.yy")
      insert(:user, user_name: "user.2", full_name: "bbbb", email: "dddd@xxx.yy")

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "aa f"}))
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "r.1"}))
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: ".2"}))
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "dd"}))
               |> json_response(:ok)

      assert Enum.count(data) == 1

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{query: "zz"}))
               |> json_response(:ok)

      assert Enum.empty?(data)
    end

    @tag authentication: [role: :admin]
    test "will return users using permission filter", %{
      conn: conn
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
               |> json_response(:ok)

      assert [user_id_1, user_id_2] ||| Enum.map(data, & &1["id"])
    end

    @tag authentication: [role: :user]
    test "will return empty list using permission filter with non admin for different permission than allow_foreign_grant_request",
         %{
           conn: conn
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
               |> json_response(:ok)

      assert [] = data
    end

    @tag authentication: [role: :user]
    test "will return users using permission filter with non admin for permission allow_foreign_grant_request",
         %{
           conn: conn,
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

      assert [user_id_2, user_id_3] ||| Enum.map(data, & &1["id"])

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
               |> json_response(:ok)

      assert [%{"id" => ^user_id_2}] = data

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :create, %{permission: permission.name}))
               |> json_response(:ok)

      assert [user_id_1, user_id_2, user_id_4] ||| Enum.map(data, & &1["id"])
    end
  end

  describe "POST /api/users/grant_requestable" do
    @tag authentication: [role: "user"]
    test "returns users for all allowed requester and requestable domains", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_2: %{id: user_2_id, full_name: user_2_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      single_params = %{
        "structures_domains" => [domain_1_id]
      }

      assert %{"data" => single_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), single_params)
               |> json_response(:ok)

      multi_params = %{
        "structures_domains" => [domain_1_id, domain_2_id]
      }

      assert %{"data" => multi_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), multi_params)
               |> json_response(:ok)

      assert single_data == multi_data

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_2_id, "full_name" => ^user_2_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = single_data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "user"]
    test "returns only users that meet all domains", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_3_id: domain_3_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_1_id, domain_2_id, domain_3_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "user"]
    test "returns only admin users if any requestable user don't meet all domains",
         %{
           conn: conn,
           claims: claims
         } do
      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_4_id: domain_4_id,
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_1_id, domain_2_id, domain_4_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "user"]
    test "returns empty list if any requestable don't meet all domains", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_4_id: domain_4_id
      } =
        grant_request_setup(claims, false)

      params = %{
        "structures_domains" => [domain_1_id, domain_2_id, domain_4_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [] = data
    end

    @tag authentication: [role: "user"]
    test "returns list if allow_foreign_grant_request is in default role", %{
      conn: conn,
      claims: claims
    } do
      CacheHelpers.put_default_permissions([:allow_foreign_grant_request])

      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_4_id: domain_4_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_2: %{id: user_2_id, full_name: user_2_full_name},
        user_3: %{id: user_3_id, full_name: user_3_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_1_id, domain_2_id, domain_4_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_2_id, "full_name" => ^user_2_full_name},
               %{"id" => ^user_3_id, "full_name" => ^user_3_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] =
               data
               |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "user"]
    test "returns empty list if requester don't meet all domains", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_5_id: domain_5_id
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_1_id, domain_2_id, domain_5_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [] = data
    end

    @tag authentication: [role: "admin"]
    test "returns list if requester is admin", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_5_id: domain_5_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_5_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "service"]
    test "returns list if requester is service", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_3_id: domain_3_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_3_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "agent"]
    test "returns list if requester is agent", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_3_id: domain_3_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_3_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "user"]
    test "returns list if create_foreign_grant_request is in default role", %{
      conn: conn,
      claims: claims
    } do
      CacheHelpers.put_default_permissions([:create_foreign_grant_request])

      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_5_id: domain_5_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_1_id, domain_2_id, domain_5_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] = data |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: :user]
    test "returns list if both permissions are in default role", %{
      conn: conn,
      claims: claims
    } do
      CacheHelpers.put_default_permissions([
        :create_foreign_grant_request,
        :allow_foreign_grant_request
      ])

      %{
        domain_6_id: domain_6_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_2: %{id: user_2_id, full_name: user_2_full_name},
        user_3: %{id: user_3_id, full_name: user_3_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        user_admin: %{id: user_admin_id, full_name: user_admin_full_name}
      } =
        grant_request_setup(claims, true)

      params = %{
        "structures_domains" => [domain_6_id]
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_2_id, "full_name" => ^user_2_full_name},
               %{"id" => ^user_3_id, "full_name" => ^user_3_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name},
               %{"id" => ^user_admin_id, "full_name" => ^user_admin_full_name}
             ] =
               data
               |> Enum.sort_by(& &1["id"])
    end

    @tag authentication: [role: "user"]
    test "returns empty list if no domains param or empty domains list", %{
      conn: conn,
      claims: claims
    } do
      grant_request_setup(claims, true)

      params = %{}

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [] = data

      params = %{
        "structures_domains" => []
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [] = data
    end

    @tag authentication: [role: "admin"]
    test "returns empty list if no domains param or empty domains list for admin", %{
      conn: conn,
      claims: claims
    } do
      grant_request_setup(claims, true)

      params = %{}

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [] = data

      params = %{
        "structures_domains" => []
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), params)
               |> json_response(:ok)

      assert [] = data
    end

    @tag authentication: [role: "user"]
    test "returns users with params", %{
      conn: conn,
      claims: claims
    } do
      %{
        domain_1_id: domain_1_id,
        domain_3_id: domain_3_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        role: %{id: role_id}
      } =
        grant_request_setup(claims, true)

      query_params = %{
        "structures_domains" => [domain_1_id],
        "query" => "user 1"
      }

      assert %{"data" => query_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), query_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name}
             ] = query_data

      role_params = %{
        "structures_domains" => [domain_1_id],
        "roles" => [role_id]
      }

      assert %{"data" => role_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), role_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name}
             ] = role_data |> Enum.sort_by(& &1["id"])

      domain_params = %{
        "structures_domains" => [domain_1_id],
        "filter_domains" => [domain_3_id]
      }

      assert %{"data" => domain_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), domain_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name}
             ] = domain_data |> Enum.sort_by(& &1["id"])

      all_params = %{
        "structures_domains" => [domain_1_id],
        "roles" => [role_id],
        "query" => user_1_full_name,
        "filter_domains" => [domain_3_id]
      }

      assert %{"data" => all_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), all_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name}
             ] = all_data
    end

    @tag authentication: [role: "user"]
    test "returns users with params but allow_foreign_grant_request is in default role", %{
      conn: conn,
      claims: claims
    } do
      CacheHelpers.put_default_permissions([:allow_foreign_grant_request])

      %{
        domain_4_id: domain_4_id,
        domain_5_id: domain_5_id,
        user_1: %{id: user_1_id, full_name: user_1_full_name},
        user_agent: %{id: user_agent_id, full_name: user_agent_full_name},
        user_service: %{id: user_service_id, full_name: user_service_full_name},
        role: %{id: role_id}
      } =
        grant_request_setup(claims, true)

      query_params = %{
        "structures_domains" => [domain_4_id],
        "query" => "user 1"
      }

      assert %{"data" => query_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), query_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name}
             ] = query_data

      role_params = %{
        "structures_domains" => [domain_4_id],
        "roles" => [role_id]
      }

      assert %{"data" => role_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), role_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name}
             ] = role_data |> Enum.sort_by(& &1["id"])

      domain_params = %{
        "structures_domains" => [domain_4_id],
        "filter_domains" => [domain_5_id]
      }

      assert %{"data" => domain_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), domain_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name},
               %{"id" => ^user_agent_id, "full_name" => ^user_agent_full_name},
               %{"id" => ^user_service_id, "full_name" => ^user_service_full_name}
             ] = domain_data |> Enum.sort_by(& &1["id"])

      all_params = %{
        "structures_domains" => [domain_4_id],
        "roles" => [role_id],
        "query" => user_1_full_name,
        "filter_domains" => [domain_5_id]
      }

      assert %{"data" => all_data} =
               conn
               |> post(Routes.user_search_path(conn, :grant_requestable), all_params)
               |> json_response(:ok)

      assert [
               %{"id" => ^user_1_id, "full_name" => ^user_1_full_name}
             ] = all_data
    end

    @tag authentication: [role: "user"]
    test "returns unauthorized if user has no view_data_structure permission", %{
      conn: conn,
      claims: claims
    } do
      %{id: domain_1_id} = CacheHelpers.put_domain()

      CacheHelpers.put_session_permissions(claims, %{
        "create_foreign_grant_request" => [domain_1_id]
      })

      params = %{
        "structures_domains" => [domain_1_id]
      }

      assert conn
             |> post(Routes.user_search_path(conn, :grant_requestable), params)
             |> json_response(:forbidden)
    end

    @tag authentication: [role: "user"]
    test "returns unauthorized if user has no create_foreign_grant_request permission", %{
      conn: conn,
      claims: claims
    } do
      %{id: domain_1_id} = CacheHelpers.put_domain()

      CacheHelpers.put_session_permissions(claims, %{
        "view_data_structure" => [domain_1_id]
      })

      params = %{
        "structures_domains" => [domain_1_id]
      }

      assert conn
             |> post(Routes.user_search_path(conn, :grant_requestable), params)
             |> json_response(:forbidden)
    end

    defp grant_request_setup(claims, generate_special_users) do
      %{id: domain_1_id} = CacheHelpers.put_domain()
      %{id: domain_2_id} = CacheHelpers.put_domain()
      %{id: domain_3_id} = CacheHelpers.put_domain()
      %{id: domain_4_id} = CacheHelpers.put_domain()
      %{id: domain_5_id} = CacheHelpers.put_domain()
      %{id: domain_6_id} = CacheHelpers.put_domain()

      CacheHelpers.put_session_permissions(claims, %{
        "create_foreign_grant_request" => [domain_1_id, domain_2_id, domain_3_id, domain_4_id],
        "view_data_structure" => [domain_6_id]
      })

      permission = insert(:permission, name: "allow_foreign_grant_request")

      %{name: role_1_name} =
        role_1 =
        insert(:role,
          name: "requestable role",
          permissions: [permission]
        )

      %{name: role_2_name} =
        role_2 =
        insert(:role,
          name: "lorem ipsum",
          permissions: [permission]
        )

      CacheHelpers.put_roles_by_permission(%{
        "allow_foreign_grant_request" => [role_1_name, role_2_name]
      })

      %{id: user_1_id} = user_1 = insert(:user, full_name: "requestable user 1")

      insert(:acl_entry, user_id: user_1_id, role: role_1, resource_id: domain_1_id)
      insert(:acl_entry, user_id: user_1_id, role: role_1, resource_id: domain_2_id)
      insert(:acl_entry, user_id: user_1_id, role: role_1, resource_id: domain_3_id)
      insert(:acl_entry, user_id: user_1_id, role: role_1, resource_id: domain_5_id)

      %{id: user_2_id} = user_2 = insert(:user, full_name: "requestable user 2")

      insert(:acl_entry, user_id: user_2_id, role: role_2, resource_id: domain_1_id)
      insert(:acl_entry, user_id: user_2_id, role: role_2, resource_id: domain_2_id)

      user_3 = insert(:user, full_name: "non requestable user")

      %{id: user_agent_id} = user_agent = insert(:user, full_name: "agent user")
      insert(:acl_entry, user_id: user_agent_id, role: role_1, resource_id: domain_1_id)
      insert(:acl_entry, user_id: user_agent_id, role: role_1, resource_id: domain_2_id)
      insert(:acl_entry, user_id: user_agent_id, role: role_1, resource_id: domain_3_id)
      insert(:acl_entry, user_id: user_agent_id, role: role_1, resource_id: domain_5_id)

      %{id: user_service_id} = user_service = insert(:user, full_name: "service user")
      insert(:acl_entry, user_id: user_service_id, role: role_1, resource_id: domain_1_id)
      insert(:acl_entry, user_id: user_service_id, role: role_1, resource_id: domain_2_id)
      insert(:acl_entry, user_id: user_service_id, role: role_1, resource_id: domain_3_id)
      insert(:acl_entry, user_id: user_service_id, role: role_1, resource_id: domain_5_id)

      user_admin =
        if generate_special_users do
          insert(:user, full_name: "admin user", role: "admin")
        else
          nil
        end

      CacheHelpers.put_acl("domain", domain_1_id, role_1_name, [
        user_1_id,
        user_agent_id,
        user_service_id
      ])

      CacheHelpers.put_acl("domain", domain_2_id, role_1_name, [
        user_1_id,
        user_agent_id,
        user_service_id
      ])

      CacheHelpers.put_acl("domain", domain_3_id, role_1_name, [
        user_1_id,
        user_agent_id,
        user_service_id
      ])

      CacheHelpers.put_acl("domain", domain_5_id, role_1_name, [
        user_1_id,
        user_agent_id,
        user_service_id
      ])

      CacheHelpers.put_acl("domain", domain_1_id, role_2_name, [user_2_id])
      CacheHelpers.put_acl("domain", domain_2_id, role_2_name, [user_2_id])

      %{
        domain_1_id: domain_1_id,
        domain_2_id: domain_2_id,
        domain_3_id: domain_3_id,
        domain_4_id: domain_4_id,
        domain_5_id: domain_5_id,
        domain_6_id: domain_6_id,
        user_1: user_1,
        user_2: user_2,
        user_3: user_3,
        user_agent: user_agent,
        user_service: user_service,
        user_admin: user_admin,
        role: role_1
      }
    end
  end
end
