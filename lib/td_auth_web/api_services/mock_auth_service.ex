defmodule TdAuthWeb.ApiServices.MockAuthService do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: MockAuthService)
  end

  def set_user_info(status_code, profile) do
    Agent.update(MockAuthService, &Map.put(&1, :user_info, {status_code, profile}))
  end

  def get_user_info(_path, _headers) do
    Agent.get(MockAuthService, &Map.get(&1, :user_info)) || {0, %{}}
  end
end
