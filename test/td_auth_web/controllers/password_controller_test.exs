defmodule TdAuthWeb.PasswordControllerTest do
  use TdAuthWeb.ConnCase

  alias TdAuth.Accounts.User

  @valid_password "new_password"
  @invalid_password "123"
  @old_password "secret hash"

  setup_all do
    start_supervised!(TdAuth.Accounts.UserLoader)
    :ok
  end

  setup do
    [user: insert(:user)]
  end

  describe "update password for admins" do
    @tag authentication: [role: :admin]
    test "updates user password when data is valid", %{
      conn: conn,
      user: %User{id: id}
    } do
      params = %{
        "user" => %{
          "id" => id,
          "new_password" => @valid_password
        }
      }

      assert %{"data" => _} =
               conn
               |> patch(Routes.password_path(conn, :update), params)
               |> json_response(:ok)
    end

    @tag authentication: [role: :admin]
    test "user password is not valid", %{
      conn: conn,
      user: %User{id: id}
    } do
      params = %{
        "user" => %{
          "id" => id,
          "new_password" => @invalid_password
        }
      }

      assert %{"errors" => _} =
               conn
               |> patch(Routes.password_path(conn, :update), params)
               |> json_response(:unprocessable_entity)
    end

    @tag authentication: [role: :user]
    test "needs admin privileges", %{conn: conn, user: %User{id: id}} do
      params = %{
        "user" => %{
          "id" => id,
          "new_password" => @valid_password
        }
      }

      assert %{"errors" => _} =
               conn
               |> patch(Routes.password_path(conn, :update), params)
               |> json_response(:forbidden)
    end
  end

  describe "update password for users" do
    @tag authentication: [role: :user]
    test "changes password when password is valid", %{conn: conn} do
      params = %{
        "user" => %{
          "new_password" => @valid_password,
          "old_password" => @old_password
        }
      }

      assert conn
             |> patch(Routes.password_path(conn, :update), params)
             |> response(:ok)
    end

    @tag authentication: [role: :admin]
    test "onws admin password when password is valid", %{conn: conn} do
      params = %{
        "user" => %{
          "new_password" => @valid_password,
          "old_password" => @old_password
        }
      }

      assert conn
             |> patch(Routes.password_path(conn, :update), params)
             |> response(:ok)
    end

    @tag authentication: [role: :admin]
    test "update onws admins password when old_password is incorrect", %{conn: conn} do
      params = %{
        "user" => %{
          "new_password" => @valid_password,
          "old_password" => "wrong_password"
        }
      }

      assert conn
             |> patch(Routes.password_path(conn, :update), params)
             |> response(:forbidden)
    end

    @tag authentication: [role: :user]
    test "update user's own password when is valid", %{conn: conn} do
      params = %{
        "user" => %{
          "new_password" => @valid_password,
          "old_password" => @old_password
        }
      }

      assert conn
             |> patch(Routes.password_path(conn, :update), params)
             |> response(:ok)
    end

    @tag authentication: [role: :user]
    test "doesn't update user's own password when is invalid", %{conn: conn} do
      params = %{
        "user" => %{
          "new_password" => "Short",
          "old_password" => @old_password
        }
      }

      assert conn
             |> patch(Routes.password_path(conn, :update), params)
             |> response(:unprocessable_entity)
    end
  end
end
