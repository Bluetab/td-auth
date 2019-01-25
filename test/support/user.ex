defmodule TdAuthWeb.User do
  @moduledoc false

  alias Poison, as: JSON
  alias TdAuthWeb.Router.Helpers, as: Routes
  import TdAuthWeb.Authentication, only: :functions
  @endpoint TdAuthWeb.Endpoint

  def user_init(user_params) do
    body = %{user: user_params} |> JSON.encode!()
    headers = get_default_headers()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.user_url(@endpoint, :init), body, headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def user_create(token, user_params) do
    headers = get_jwt_headers(token)
    body = %{user: user_params} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.user_url(@endpoint, :create), body, headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def user_update(token, target_user_id, user_params) do
    headers = get_jwt_headers(token)
    body = %{user: user_params} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.put!(Routes.user_url(@endpoint, :update, target_user_id), body, headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def user_delete(token, target_user_id) do
    headers = get_jwt_headers(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.delete!(Routes.user_url(@endpoint, :delete, target_user_id), headers, [])

    {:ok, status_code, resp}
  end

  def user_list(token) do
    headers = get_jwt_headers(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(Routes.user_url(@endpoint, :index), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def get_user_by_name(token, user_name) do
    {:ok, _status_code, json_resp} = user_list(token)
    Enum.find(json_resp["data"], fn user -> user["user_name"] == user_name end)
  end

  def change_password(token, user_id, old_password, new_password) do
    headers = get_jwt_headers(token)
    body = %{old_password: old_password, new_password: new_password} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.patch!(
        Routes.user_user_url(@endpoint, :change_password, user_id),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end
end
