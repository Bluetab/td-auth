defmodule TdAuthWeb.Password do
  @moduledoc false

  import TdAuthWeb.Authentication, only: :functions

  alias TdAuthWeb.Router.Helpers, as: Routes

  @endpoint TdAuthWeb.Endpoint

  def update_password(token, %{new_password: _new_password, old_password: _old_password} = user_params) do
    headers = get_jwt_headers(token)
    body = Jason.encode!(%{"user" => user_params})
    %HTTPoison.Response{status_code: status_code} =
      HTTPoison.put!(Routes.password_url(@endpoint, :update), body, headers, [])
    {:ok, status_code}
  end

  def update_password(token, target_user_id, new_password) do
    headers = get_jwt_headers(token)

    body = Jason.encode!(%{"user" =>  %{"id" => target_user_id, "new_password" => new_password}})
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.put!(Routes.password_url(@endpoint, :update), body, headers, [])

    {:ok, status_code, Jason.decode!(resp)}
  end

end
