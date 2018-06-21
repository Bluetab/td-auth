defmodule TdAuth.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  use TdAuthWeb.ConnCase
  import TdAuthWeb.ResponseCode
  import TdAuthWeb.Authentication, only: :functions
  import TdAuthWeb.User, only: :functions

  # Scenario: logging
  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/,
          %{user_name: user_name, user_passwd: user_passwd},
          state do
    {_, status_code, json_resp} = session_create(user_name, user_passwd)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"]})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
          %{status_code: status_code},
          state do
    assert status_code == to_response_code(state[:status_code])
  end

  # Scenario: logging error
  defgiven ~r/^a superadmin user logged in the application$/, _, state do
    {_, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{app_token: json_resp["token"]})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to create a user "(?<new_user_name>[^"]+)" with password "(?<new_password>[^"]+)"$/,
          %{user_name: _user_name, new_user_name: new_user_name, new_password: new_password},
          state do
    {_, status_code, json_resp} =
      user_create(state[:token], %{
        user_name: new_user_name,
        password: new_password,
        email: "some@email.com"
      })

    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defand ~r/^user "(?<new_user_name>[^"]+)" can be authenticated with password "(?<new_password>[^"]+)"$/,
         %{new_user_name: new_user_name, new_password: new_password},
         _state do
    {_, status_code, json_resp} = session_create(new_user_name, new_password)
    assert rc_created() == to_response_code(status_code)
    assert json_resp["token"] != nil
  end

  # Scenario: logging error for non existing user
  defwhen ~r/^"(?<user_name>[^"]+)" tries to modify his password with following data:$/,
          %{
            user_name: user_name,
            table: [%{old_password: old_password, new_password: new_password}]
          },
          state do
    {_, status_code} =
      change_password(
        state[:token],
        get_user_by_name(state[:app_token], user_name)["id"],
        old_password,
        new_password
      )

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to modify "(?<other_user_name>[^"]+)" password with following data:$/,
          %{
            user_name: _user_name,
            other_user_name: other_user_name,
            table: [%{old_password: old_password, new_password: new_password}]
          },
          state do
    {_, status_code} =
      change_password(
        state[:token],
        get_user_by_name(state[:app_token], other_user_name)["id"],
        old_password,
        new_password
      )

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # Scenario: Error when creating a new user in the application by a non admin user
  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" without "super-admin" permission$/,
           %{user_name: user_name, password: password},
           state do
    {_, _status_code, json_resp} = session_create("app-admin", "mypass")
    token = json_resp["token"]

    {_, _status_code, _json_resp} =
      user_create(token, %{user_name: user_name, password: password, email: "some@email.com"})

    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/,
         %{user_name: user_name, password: password},
         state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"]})}
  end

  defand ~r/^user "(?<user_name>[^"]+)" can not be authenticated with password "(?<password>[^"]+)"$/,
         %{user_name: user_name, password: password},
         _state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_forbidden() == to_response_code(status_code)
    assert json_resp["token"] == nil
  end

  # Scenario: Error when creating a duplicated user
  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with "super-admin" permission$/,
           %{user_name: user_name, password: password},
           state do
    {_, _status_code, json_resp} = session_create("app-admin", "mypass")
    token = json_resp["token"]

    {_, status_code, _json_resp} =
      user_create(token, %{
        user_name: user_name,
        password: password,
        is_admin: true,
        email: "some@email.com"
      })

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with super-admin property (?<is_super_admin>[^"]+)/,
           %{user_name: user_name, password: password, is_super_admin: is_super_admin},
           state do
    {_, _status_code, json_resp} = session_create("app-admin", "mypass")
    token = json_resp["token"]

    {_, status_code, json_resp} =
      user_create(token, %{
        user_name: user_name,
        password: password,
        is_admin: is_super_admin == "yes",
        email: "some@email.com"
      })

    assert json_resp["data"]["is_admin"] == (is_super_admin == "yes")
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with super-admin property "(?<is_super_admin>[^"]+)"/,
           %{user_name: user_name, password: password, is_super_admin: is_super_admin},
           state do
    {_, _status_code, json_resp} = session_create("app-admin", "mypass")
    token = json_resp["token"]

    {_, status_code, json_resp} =
      user_create(token, %{
        user_name: user_name,
        password: password,
        is_admin: is_super_admin == "true",
        email: "some@email.com"
      })

    assert json_resp["data"]["is_admin"] == (is_super_admin == "true")
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to modify user "(?<target_user_name>[^"]+)" with following data:$/,
          %{
            user_name: _user_name,
            target_user_name: target_user_name,
            table: [%{is_admin: is_admin}]
          },
          state do
    target_user = get_user_by_name(state[:app_token], target_user_name)

    {:ok, status_code, _json_resp} =
      user_update(state[:token], target_user["id"], %{is_admin: is_admin != "false"})

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to delete user "(?<target_user_name>[^"]+)"$/,
          %{user_name: _user_name, target_user_name: target_user_name},
          state do
    target_user = get_user_by_name(state[:app_token], target_user_name)
    {:ok, status_code, _resp} = user_delete(state[:token], target_user["id"])
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result "(?<actual_result>[^"]+)" is "(?<expected_result>[^"]+)" user "(?<user_name>[^"]+)" does not exist$/,
         %{actual_result: actual_result, expected_result: expected_result, user_name: user_name},
         state do
    if actual_result == expected_result do
      user = get_user_by_name(state[:token], user_name)
      assert !user
    end
  end

  defand ~r/^if result "(?<actual_result>[^"]+)" is not "(?<expected_result>[^"]+)" user "(?<user_name>[^"]+)" can be authenticated with password "(?<password>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           user_name: user_name,
           password: password
         },
         _state do
    if actual_result != expected_result do
      {_, status_code, json_resp} = session_create(user_name, password)
      assert rc_created() == to_response_code(status_code)
      assert json_resp["token"] != nil
    end
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to reset "(?<other_user_name>[^"]+)" password with new_password "(?<new_password>[^"]+)"$/,
          %{user_name: _user_name, other_user_name: other_user_name, new_password: new_password},
          state do
    target_user = get_user_by_name(state[:app_token], other_user_name)

    {:ok, status_code, _json_resp} =
      user_update(state[:token], target_user["id"], %{password: new_password})

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to reset his "(?<property>[^"]+)" with new property value "(?<new_value>[^"]+)"$/,
          %{user_name: user_name, property: property, new_value: new_value},
          state do
    target_user = get_user_by_name(state[:app_token], user_name)

    {:ok, status_code, _json_resp} =
      user_update(state[:token], target_user["id"], Map.put(%{}, property, new_value))

    {:ok, Map.merge(state, %{status_code: status_code})}
  end
end
