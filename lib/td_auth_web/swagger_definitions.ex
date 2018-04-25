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
          groups (Schema.new do
                      type :array
                      items Schema.ref(:Group)
                    end)
        end
        example %{
          id: 123,
          user_name: "myuser",
          is_admin: false,
          password: "myuserpass",
          email: "some@email.com",
          full_name: "My User",
          groups: [%{
            id: 321,
            name: "group1"
          }
          ]
        }
      end,
      UserCreateProps: swagger_schema do
        properties do
          user_name :string, "user name", required: true
          is_admin :boolean, "is admin flag"
          password :string, "user password", required: true
          email :string, "some@email.com", required: true
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
          groups (Schema.new do
                      type :array
                      items Schema.ref(:Group)
                    end)
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
        end
        example %{
          id: 123,
          name: "mygroup"
        }
      end,
      GroupCreateProps: swagger_schema do
        properties do
          name :string, "name", required: true
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
end
