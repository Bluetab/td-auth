defmodule TdAuth.HttpClient do
  @moduledoc """
  An HTTP client to allow `OpenIDConnect` to use configurable proxy
  authentication.
  """
  use HTTPoison.Base

  def process_request_options(options) do
    IO.puts("process_request_options")
    IO.inspect(__MODULE__, label: "__MODULE__")

    :td_auth
    |> Application.get_env(__MODULE__, [])
    |> IO.inspect(label: "GET_ENV")
    |> Enum.reduce(options, &put_option/2)
  end

  defp put_option({:proxy, {host, port}}, options) when is_binary(host) and is_integer(port) do
    Keyword.put_new(options, :proxy, {host, port})
  end

  defp put_option({:proxy_auth, {user, password}}, options)
       when is_binary(user) and is_binary(password) do
    Keyword.put_new(options, :proxy_auth, {user, password})
  end

  defp put_option({:hackney, hackney_opts}, options) do
    Keyword.put_new(options, :hackney, hackney_opts)
  end

  defp put_option(_, options), do: options
end
