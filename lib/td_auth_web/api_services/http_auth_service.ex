defmodule TdAuthWeb.ApiServices.HttpAuthService do
  @moduledoc false

  def get_user_info(path, headers) do
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(path, headers)
      {status_code, resp}
  end

end
