defmodule TdAuth.Ldap.EldapMock do
  @moduledoc false

  use GenServer

  def start_link(_, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def get_attribute_value(attribute) do
    GenServer.call(__MODULE__, {:get_attribute_value, attribute})
  end

  def set_attribute_value(attribute, value) do
    GenServer.cast(__MODULE__, {:set_attribute_value, attribute, value})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:get_attribute_value, attribute}, _, attrs) do
    {:reply, Map.get(attrs, to_charlist(attribute)), attrs}
  end

  @impl true
  def handle_cast({:set_attribute_value, attribute, value}, attrs) do
    {:noreply, Map.put(attrs, to_charlist(attribute), to_charlist(value))}
  end

  def search(_conn, keywords) do
    attribute =
      keywords
      |> Keyword.get(:attributes)
      |> hd

    values =
      case get_attribute_value(attribute) do
        nil -> []
        value -> [value]
      end

    attributes = [{attribute, values}]

    search_result = {
      :eldap_search_result,
      [{:eldap_entry, nil, attributes}],
      nil
    }

    {:ok, search_result}
  end

  def get_attribute!(_, _), do: nil
end
