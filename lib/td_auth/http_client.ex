defmodule TdAuth.HttpClient do
  @moduledoc """
  An HTTP client to allow `OpenIDConnect` to use configurable proxy
  authentication.
  """
  use HTTPoison.Base

  alias TdAuth.Map.Helpers

  def process_request_url(url) do
    :td_auth
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:url_prefix)
    |> case do
      nil -> url
      url_prefix -> url_prefix <> url
    end
  end

  def process_request_options(options) do
    :td_auth
    |> Application.get_env(__MODULE__, [])
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
    Helpers.to_map(hackney_opts)
    |> maybe_put_cacertfile(options)
  end

  defp put_option({:ssl, []}, options), do: options

  defp put_option({:ssl, ssl_opts}, options), do: Keyword.put_new(options, :ssl, ssl_opts)

  defp put_option(_, options), do: options

  defp maybe_put_cacertfile(%{ssl_options: %{cacertfile: nil}}, options) do
    options
  end

  defp maybe_put_cacertfile(%{ssl_options: %{cacertfile: cacertfile}}, options) do
    Keyword.put_new(options, :hackney, ssl_options: [cacertfile: cacertfile])
  end

  defp maybe_put_cacertfile(_, options) do
    options
  end
end
