defmodule TdAuthWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

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
        end
        example %{
          id: 123,
          user_name: "myuser",
          is_admin: false,
          password: "myuserpass"
        }
      end,
      UserCreateProps: swagger_schema do
        properties do
          user_name :string, "user name", required: true
          is_admin :boolean, "is admin flag"
          password :string, "user password", required: true
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
end
