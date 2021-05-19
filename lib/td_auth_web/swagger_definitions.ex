defmodule TdAuthWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def session_swagger_definitions do
    %{
      Token:
        swagger_schema do
          title("Auth Token")

          properties do
            token(:string, "token")
            refresh_token(:string, "refresh token", required: true)
            has_permissions(:boolean, "has_permissions", required: false)
            refresh_token(:string, "access_method")
          end
        end,
      Claims:
        swagger_schema do
          properties do
            user_name(:string, "user name", required: true)
            password(:string, "password", required: true)
          end
        end,
      RefreshSessionCreate:
        swagger_schema do
          properties do
            refresh_token(:string, "refresh token", required: true)
          end
        end,
      SessionCreate:
        swagger_schema do
          properties do
            user(Schema.ref(:Claims))
          end
        end
    }
  end

  def auth_swagger_definitions do
    %{
      AuthenticationMethodsResponse:
        swagger_schema do
          properties do
            data(
              Schema.new do
                properties do
                  oidc(:string, "oidc url", required: false)
                  auth0(:object, "auth0 config", required: false)
                end
              end
            )
          end
        end,
      AuthenticationMethodResource:
        swagger_schema do
          title("Authentication Method Resource")
          description("Authentication Method Resource")

          properties do
            url(:string, "authentication url", required: true)
          end
        end
    }
  end

  def user_swagger_definitions do
    %{
      UserAclResource:
        swagger_schema do
          title("User Acl Resource")
          description("User Acl Resource")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "resource name", required: true)
            type(:string, "resource type", required: true)
          end
        end,
      UserAclRole:
        swagger_schema do
          title("User Acl Role")
          description("User Acl Role")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "role name", required: true)
          end
        end,
      UserAclGroup:
        swagger_schema do
          title("User Acl Group")
          description("User Acl Group")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "group name", required: true)
          end
        end,
      UserAcl:
        swagger_schema do
          title("User Acl")
          description("User Acl")

          properties do
            resource(Schema.ref(:UserAclResource))
            role(Schema.ref(:UserAclRole))
            group(Schema.ref(:UserAclGroup))
          end
        end,
      UserAcls:
        swagger_schema do
          title("User Acls")
          description("A collection of User Acls")
          type(:array)
          items(Schema.ref(:UserAcl))
        end,
      User:
        swagger_schema do
          title("User")
          description("User entity")

          properties do
            id(:integer, "unique identifier", required: true)
            user_name(:string, "user name", required: true)
            is_admin(:boolean, "is admin flag (deprecated)")
            role(:string, "user role (admin, user or service)")
            password(:string, "user password")
            email(:string, "email", required: true)
            full_name(:string, "full name")
            groups(Schema.array(:string))
            acls(Schema.ref(:UserAcls))
          end

          example(%{
            id: 123,
            user_name: "myuser",
            password: "myuserpass",
            email: "some@email.com",
            full_name: "My User",
            groups: ["group1"],
            acls: [
              %{
                resource: %{id: 1, name: "foo", type: "domain"},
                role: %{id: 2, name: "bar"},
                group: %{id: 3, name: "goo"}
              }
            ]
          })
        end,
      UserCreateProps:
        swagger_schema do
          properties do
            user_name(:string, "user name", required: true)
            is_admin(:boolean, "is admin flag (deprecated)")
            password(:string, "user password", required: true)
            email(:string, "some@email.com", required: true)
            role(:string, "user role")
            groups(Schema.array(:string))
          end
        end,
      UserCreate:
        swagger_schema do
          properties do
            user(Schema.ref(:UserCreateProps))
          end
        end,
      UserUpdateProps:
        swagger_schema do
          properties do
            user_name(:string, "user name", required: true)
            is_admin(:boolean, "is admin flag (deprecated)")
            password(:string, "user password", required: true)
            email(:string, "some@email.com", required: true)
            role(:string, "user role")
            groups(Schema.array(:string))
          end
        end,
      UserUpdate:
        swagger_schema do
          properties do
            user(Schema.ref(:UserUpdateProps))
          end
        end,
      UserChangePassword:
        swagger_schema do
          properties do
            old_password(:string, "current password", required: true)
            new_password(:string, "new password", required: true)
          end
        end,
      UserUpdatePassword:
        swagger_schema do
          properties do
            new_password(:string, "new password", required: true)
          end
        end,
      Users:
        swagger_schema do
          title("Users")
          description("A collection of Users")
          type(:array)
          items(Schema.ref(:User))
        end,
      UserResponseAttrs:
        swagger_schema do
          properties do
            id(:integer, "unique identifier", required: true)
            user_name(:string, "user name", required: true)
            email(:string, "email", required: true)
            role(:string, "role", required: true)
            full_name([:string, :null], "full name")
            groups(Schema.array(:string))
          end
        end,
      UserSearchResponseAttrs:
        swagger_schema do
          properties do
            id(:integer, "unique identifier", required: true)
            full_name([:string, :null], "full name")
          end
        end,
      UserResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:UserResponseAttrs))
          end
        end,
      UserSearchResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:UserSearchResponseAttrs))
          end
        end,
      UsersResponse:
        swagger_schema do
          type(:array)
          items(Schema.ref(:UserResponseAttrs))
        end,
      UsersSearchResponse:
        swagger_schema do
          type(:array)
          items(Schema.ref(:UserSearchResponseAttrs))
        end,
      UsersResponseData:
        swagger_schema do
          properties do
            data(Schema.ref(:UsersResponse))
          end
        end,
      UsersSearchResponseData:
        swagger_schema do
          properties do
            data(Schema.ref(:UsersSearchResponse))
          end
        end,
      PermissionDomainsResponseData:
        swagger_schema do
          properties do
            permission_domains(Schema.ref(:PermissionDomainsResponse))
          end
        end,
      PermissionDomainsResponse:
        swagger_schema do
          type(:array)
          items(Schema.ref(:PermissionDomainsAttrs))
        end,
      PermissionDomainsAttrs:
        swagger_schema do
          properties do
            permission(:string, "permission name", required: true)
            domains(Schema.ref(:Domains))
          end
        end,
      Domains:
        swagger_schema do
          title("Domains")
          description("A collection of domains")
          type(:array)
          items(Schema.ref(:Domain))
        end,
      Domain:
        swagger_schema do
          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "domain name", required: true)
          end
        end
    }
  end

  def group_swagger_definitions do
    %{
      Group:
        swagger_schema do
          title("Group")
          description("Group entity")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "name", required: true)
            description(:string, "description")
          end

          example(%{
            id: 123,
            name: "mygroup",
            description: "mydescription"
          })
        end,
      GroupCreateProps:
        swagger_schema do
          properties do
            name(:string, "name", required: true)
            description(:string, "description")
          end
        end,
      GroupCreate:
        swagger_schema do
          properties do
            group(Schema.ref(:GroupCreateProps))
          end
        end,
      GroupsCreate:
        swagger_schema do
          properties do
            groups(
              Schema.new do
                type(:array)
                items(Schema.ref(:GroupCreateProps))
              end
            )
          end
        end,
      GroupUpdateProps:
        swagger_schema do
          properties do
            name(:string, "name", required: true)
            description(:string, "description")
          end
        end,
      GroupUpdate:
        swagger_schema do
          properties do
            group(Schema.ref(:GroupUpdateProps))
          end
        end,
      Groups:
        swagger_schema do
          title("Groups")
          description("A collection of Groups")
          type(:array)
          items(Schema.ref(:Group))
        end,
      GroupResponseAttrs:
        swagger_schema do
          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "name", required: true)
            description(:string, "description")
          end
        end,
      GroupResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:GroupResponseAttrs))
          end
        end,
      GroupsResponse:
        swagger_schema do
          type(:array)
          items(Schema.ref(:GroupResponseAttrs))
        end,
      GroupsResponseData:
        swagger_schema do
          properties do
            data(Schema.ref(:GroupsResponse))
          end
        end
    }
  end

  def acl_entry_swagger_definitions do
    %{
      AclEntry:
        swagger_schema do
          title("Acl entry")
          description("An Acl entry")

          properties do
            id(:integer, "unique identifier", required: true)
            group_id(:integer, "id of group", nullable: true)
            user_id(:integer, "id of user", nullable: true)
            resource_id(:integer, "id of resource", required: true)
            resource_type(:string, "type of resource: domain", required: true)
            role_id(:integer, "id of role", required: true)
            description(:string, "desctiption of acl", nullable: true)
          end
        end,
      AclEntryCreateUpdate:
        swagger_schema do
          properties do
            acl_entry(
              Schema.new do
                properties do
                  group_id(:integer, "id of group")
                  user_id(:integer, "id of user")
                  resource_id(:integer, "id of resource", required: true)
                  resource_type(:string, "type of resource: domain", required: true)
                  role_id(:integer, "id of role", required: true)
                end
              end
            )
          end
        end,
      AclEntryCreateOrUpdate:
        swagger_schema do
          properties do
            acl_entry(
              Schema.new do
                properties do
                  group_id(:integer, "id of group")
                  user_id(:integer, "id of user")
                  resource_id(:integer, "id of resource", required: true)
                  resource_type(:string, "type of resource: domain", required: true)
                  role_name(:string, "role name", required: true)
                end
              end
            )
          end
        end,
      AclEntries:
        swagger_schema do
          title("Acl entries")
          description("A collection of Acl Entry")
          type(:array)
          items(Schema.ref(:AclEntry))
        end,
      AclEntryResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:AclEntry))
          end
        end,
      AclEntriesResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:AclEntries))
          end
        end,
      ResourceAclEntriesResponse:
        swagger_schema do
          properties do
            _embedded(Schema.ref(:EmbeddedAclEntries))
            _links(Schema.ref(:Links))
          end
        end,
      Links:
        swagger_schema do
          properties do
            self(
              Schema.new do
                properties do
                  href(:string, "the url")

                  methods(
                    Schema.new do
                      type(:array)
                    end
                  )
                end
              end
            )
          end
        end,
      EmbeddedAclEntries:
        swagger_schema do
          properties do
            acl_entries(
              Schema.new do
                type(:array)
                items(Schema.ref(:EmbeddedAclEntry))
              end
            )
          end
        end,
      EmbeddedAclEntry:
        swagger_schema do
          properties do
            acl_entry_id(:integer, "id of acl entry")
            description(:string, "description", nullable: true)
            principal_type(:string, "principal type (user or group)")
            principal(Schema.ref(:Principal))
            role_id(:integer, "id of the role")
            role_name(:string, "name of the role")
          end
        end,
      Principal:
        swagger_schema do
          properties do
            id(:integer, "id of the principal (user or group)")
            full_name(:string, "full name of the principal")
            user_name(:string, "user name of the principal")
            name(:string, "name of the principal")
          end
        end,
      ResourceUserRolesResponse:
        swagger_schema do
          title("Resource User Roles")
          description("A collection of roles with corresponding users")
          type(:array)
          items(Schema.ref(:ResourceUserRolesItem))
        end,
      ResourceUserRolesItem:
        swagger_schema do
          properties do
            role_name(:string, "role name", required: true)

            users(
              Schema.new do
                type(:array)
                items(Schema.ref(:UserItem))
              end
            )
          end
        end,
      UserItem:
        swagger_schema do
          properties do
            id(:integer, "user id")
            user_name(:string, "user name")
            full_name([:string, :null], "full name")
          end
        end
    }
  end

  def permission_swagger_definitions do
    %{
      Permission:
        swagger_schema do
          title("Permission")
          description("Permission")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "permission name", required: true)
            permission_group(:object, "permission group", required: false)
          end
        end,
      PermissionItem:
        swagger_schema do
          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "permission name")
          end
        end,
      PermissionItems:
        swagger_schema do
          type(:array)
          items(Schema.ref(:PermissionItem))
        end,
      AddPermissions:
        swagger_schema do
          properties do
            permissions(Schema.ref(:PermissionItems))
          end
        end,
      Permissions:
        swagger_schema do
          title("Roles")
          description("A collection of Permissions")
          type(:array)
          items(Schema.ref(:Role))
        end,
      PermissionResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Permission))
          end
        end,
      PermissionsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Permissions))
          end
        end
    }
  end

  def permission_group_swagger_definitions do
    %{
      PermissionGroup:
        swagger_schema do
          title("PermissionGroup")
          description("Groups of permissions")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "group's name", required: true)
          end
        end,
      PermissionGroupItem:
        swagger_schema do
          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "permission group name")
          end
        end,
      PermissionGroupCreateUpdate:
        swagger_schema do
          properties do
            permission_group(Schema.ref(:PermissionGroupItem))
          end
        end,
      PermissionGroups:
        swagger_schema do
          title("Permission Groups")
          description("A collection of groups")
          type(:array)
          items(Schema.ref(:PermissionGroup))
        end,
      PermissionGroupResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:PermissionGroup))
          end
        end,
      PermissionGroupsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:PermissionGroups))
          end
        end
    }
  end

  def role_swagger_definitions do
    %{
      Role:
        swagger_schema do
          title("Role")
          description("Role")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "role name", required: true)
            is_default(:boolean, "is default role?", required: false)
          end
        end,
      Roles:
        swagger_schema do
          title("Roles")
          description("A collection of Roles")
          type(:array)
          items(Schema.ref(:Role))
        end,
      RoleCreateUpdate:
        swagger_schema do
          properties do
            role(
              Schema.new do
                properties do
                  name(:string, "role name", required: true)
                  is_default(:boolean, "is default role?", required: false, default: false)
                end
              end
            )
          end
        end,
      RoleResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Role))
          end
        end,
      RolesResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Roles))
          end
        end
    }
  end
end
