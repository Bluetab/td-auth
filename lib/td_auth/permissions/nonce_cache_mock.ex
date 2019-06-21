defmodule TdAuth.NonceCacheMock do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: NonceCacheMock)
  end

  def create_nonce(content) do
    nonce = generate_random_string()
    Agent.update(NonceCacheMock, &Map.put(&1, nonce, content))
    nonce
  end

  def pop(nonce) do
    Agent.get(NonceCacheMock, &Map.get(&1, nonce))
  end

  defp generate_random_string do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
    |> binary_part(0, 16)
  end
end
