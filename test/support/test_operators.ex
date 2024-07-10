defmodule TdAuth.TestOperators do
  @moduledoc """
  Equality operators for tests
  """

  def a <~> b, do: approximately_equal(a, b)
  def a ||| b, do: approximately_equal(sorted(a), sorted(b))

  defp sorted([%{id: _} | _] = list) do
    Enum.sort_by(list, & &1.id)
  end

  defp sorted([%{"id" => _} | _] = list) do
    Enum.sort_by(list, &Map.get(&1, "id"))
  end

  defp sorted(list), do: Enum.sort(list)

  defp approximately_equal([h | t], [h2 | t2]) do
    approximately_equal(h, h2) && approximately_equal(t, t2)
  end

  defp approximately_equal(%{"id" => id1}, %{"id" => id2}), do: id1 == id2

  defp approximately_equal(%{id: id1}, %{id: id2}), do: id1 == id2

  defp approximately_equal(a, b), do: a == b
end
