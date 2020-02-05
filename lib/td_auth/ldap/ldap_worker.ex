defmodule TdAuth.Ldap.LdapWorker do
  @moduledoc false

  use GenServer

  def start_link(filename, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, filename, name: name)
  end

  def get_validations do
    GenServer.call(__MODULE__, {:get_validations})
  end

  def set_validations(validations) do
    GenServer.cast(__MODULE__, {:set_validations, validations})
  end

  @impl true
  def init("") do
    {:ok, []}
  end

  @impl true
  def init(filename) do
    filename
    |> File.read!()
    |> Jason.decode()
    |> check_validation_format
  end

  @impl true
  def handle_call({:get_validations}, _, config) do
    {:reply, config, config}
  end

  @impl true
  def handle_cast({:set_validations, validations}, _) do
    {:noreply, validations}
  end

  defp check_validation_format({:ok, validations}) when is_list(validations) do
    {:ok, validations}
  end

  defp check_validation_format({:ok, _}), do: {:error, "ldap validations must be a list"}
  defp check_validation_format(error), do: error
end
