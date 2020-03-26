defmodule TdAuthWeb.ApiServices.MockAuth0Service do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set_user_info(status_code, profile) do
    Agent.update(__MODULE__, &Map.put(&1, :user_info, {status_code, profile}))
  end

  def get_user_info(_path, _headers) do
    Agent.get(__MODULE__, &Map.get(&1, :user_info)) || {0, %{}}
  end
end
