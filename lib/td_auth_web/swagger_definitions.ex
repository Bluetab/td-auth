defmodule TdAuthWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def session_swagger_definitions do
    %{
      Token: swagger_schema do
        title "Auth Token"
        properties do
          token :string, "token"
          refresh_token :string, "refresh token", required: true
        end
      end,
      Session: swagger_schema do
        properties do
          user_name :string, "user name", required: true
          password :string, "password", required: true
        end
      end,
      RefreshSessionCreate: swagger_schema do
        properties do
          refresh_token :string, "refresh token", required: true
        end
      end,
      SessionCreate: swagger_schema do
        properties do
          user Schema.ref(:Session)
        end
      end
    }
  end

  def user_swagger_definitions do
    %{
      User: swagger_schema do
        title "User"
        description "User entity"
        properties do
          id :integer, "unique identifier", required: true
          user_name :string, "user name", required: true
          is_admin :boolean, "flag is admin", required: true
          password :string, "user password"
          email :string, "email", required: true
          full_name :string, "full name"
          groups Schema.array(:string)
        end
        example %{
          id: 123,
          user_name: "myuser",
          is_admin: false,
          password: "myuserpass",
          email: "some@email.com",
          full_name: "My User",
          groups: ["group1"]
        }
      end,
      UserCreateProps: swagger_schema do
        properties do
          user_name :string, "user name", required: true
          is_admin :boolean, "is admin flag"
          password :string, "user password", required: true
          email :string, "some@email.com", required: true
          groups Schema.array(:string)
        end
      end,
      UserCreate: swagger_schema do
        properties do
          user Schema.ref(:UserCreateProps)
        end
      end,
      UserUpdateProps: swagger_schema do
        properties do
          user_name :string, "user name", required: true
          is_admin :boolean, "is admin flag"
          password :string, "user password", required: true
          email :string, "some@email.com", required: true
          groups Schema.array(:string)
        end
      end,
      UserUpdate: swagger_schema do
        properties do
          user Schema.ref(:UserUpdateProps)
        end
      end,
      UserChangePassword: swagger_schema do
        properties do
          old_password :string, "current password", required: true
          new_password :string, "new password", required: true
        end
      end,
      Users: swagger_schema do
        title "Users"
        description "A collection of Users"
        type :array
        items Schema.ref(:User)
      end,
      UserResponseAttrs: swagger_schema do
        properties do
          id :integer, "unique identifier", required: true
          user_name :string, "user name", required: true
          is_admin :boolean, "flag is admin", required: true
          email :string, "email", required: true
          full_name [:string, :null], "full name"
          groups Schema.array(:string)
        end
      end,
      UserResponse: swagger_schema do
        properties do
          data Schema.ref(:UserResponseAttrs)
        end
      end,
      UsersResponse: swagger_schema do
        type :array
        items Schema.ref(:UserResponseAttrs)
      end,
      UsersResponseData: swagger_schema do
        properties do
          data Schema.ref(:UsersResponse)
        end
      end
    }
  end

  def group_swagger_definitions do
    %{
      Group: swagger_schema do
        title "Group"
        description "Group entity"
        properties do
          id :integer, "unique identifier", required: true
          name :string, "name", required: true
          description :string, "description"
        end
        example %{
          id: 123,
          name: "mygroup",
          description: "mydescription"
        }
      end,
      GroupCreateProps: swagger_schema do
        properties do
          name :string, "name", required: true
          description :string, "description"
        end
      end,
      GroupCreate: swagger_schema do
        properties do
          group Schema.ref(:GroupCreateProps)
        end
      end,
      GroupsCreate: swagger_schema do
        properties do
          groups (Schema.new do
                      type :array
                      items Schema.ref(:GroupCreateProps)
                    end)
        end
      end,
      GroupUpdateProps: swagger_schema do
        properties do
          name :string, "name", required: true
          description :string, "description"
        end
      end,
      GroupUpdate: swagger_schema do
        properties do
          group Schema.ref(:GroupUpdateProps)
        end
      end,
      Groups: swagger_schema do
        title "Groups"
        description "A collection of Groups"
        type :array
        items Schema.ref(:Group)
      end,
      GroupResponseAttrs: swagger_schema do
        properties do
          id :integer, "unique identifier", required: true
          name :string, "name", required: true
          description :string, "description"
        end
      end,
      GroupResponse: swagger_schema do
        properties do
          data Schema.ref(:GroupResponseAttrs)
        end
      end,
      GroupsResponse: swagger_schema do
        type :array
        items Schema.ref(:GroupResponseAttrs)
      end,
      GroupsResponseData: swagger_schema do
        properties do
          data Schema.ref(:GroupsResponse)
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
            principal_id(:integer, "id of principal", required: true)
            principal_type(:string, "type of principal: user", required: true)
            resource_id(:integer, "id of resource", required: true)
            resource_type(:string, "type of resource: domain", required: true)
            role_id(:integer, "id of role", required: true)
          end
        end,
      AclEntryCreateUpdate:
        swagger_schema do
          properties do
            acl_entry(
              Schema.new do
                properties do
                  principal_id(:integer, "id of principal", required: true)
                  principal_type(:string, "type of principal: user", required: true)
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
                  principal_id(:integer, "id of principal", required: true)
                  principal_type(:string, "type of principal: user", required: true)
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
      AddPermissionsToRole:
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

  def role_swagger_definitions do
    %{
      Role:
        swagger_schema do
          title("Role")
          description("Role")

          properties do
            id(:integer, "unique identifier", required: true)
            name(:string, "role name", required: true)
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
