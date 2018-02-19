defmodule TdAuth.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  use TdAuthWeb.ConnCase
  import TdAuthWeb.ResponseCode
  import TdAuthWeb.Authentication, only: :functions
  import TdAuthWeb.User, only: :functions

  # Scenario: logging
  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/, %{user_name: user_name, user_passwd: user_passwd}, state do
    {_, status_code, json_resp} = session_create(user_name, user_passwd)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"]})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  # Scenario: logging error
  defgiven ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to create a user "(?<new_user_name>[^"]+)" with password "(?<new_password>[^"]+)"$/, %{user_name: _user_name, new_user_name: new_user_name, new_password: new_password}, state do
    {_, status_code, json_resp} = user_create(state[:token], %{user_name: new_user_name, password: new_password})
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defand ~r/^user "(?<new_user_name>[^"]+)" can be authenticated with password "(?<new_password>[^"]+)"$/, %{new_user_name: new_user_name, new_password: new_password}, _state do
    {_, status_code, json_resp} = session_create(new_user_name, new_password)
      assert rc_created() == to_response_code(status_code)
      assert json_resp["token"] != nil
  end

  # Scenario: logging error for non existing user
  defwhen ~r/^"johndoe" tries to modify his password with following data:$/,
          %{table: [%{old_password: old_password, new_password: new_password}]}, state do
      {_, status_code} = session_change_password(state[:token], old_password, new_password)
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # Scenario: Error when creating a new user in the application by a non admin user
  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" without "super-admin" permission$/, %{user_name: user_name, password: password}, state do
    {_, _status_code, json_resp} = session_create("app-admin", "mypass")
    token = json_resp["token"]
    {_, _status_code, _json_resp} = user_create(token, %{user_name: user_name, password: password})
    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"]})}
  end

  defand ~r/^user "(?<user_name>[^"]+)" can not be authenticated with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, _state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_forbidden() == to_response_code(status_code)
    assert json_resp["token"] == nil
  end

  # Scenario: Error when creating a duplicated user
  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with "super-admin" permission$/, %{user_name: user_name, password: password}, state do
    {_, _status_code, json_resp} = session_create("app-admin", "mypass")
    token = json_resp["token"]
    {_, status_code, json_resp} = user_create(token, %{user_name: user_name, password: password, is_admin: true})
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"]})}
  end
end
