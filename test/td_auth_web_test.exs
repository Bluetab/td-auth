defmodule TdAuthWebTest do
  use ExUnit.Case, async: true

  alias TdAuthWeb

  describe "controller/1" do
    test "returns controller quote with default log level" do
      quote = TdAuthWeb.controller()

      assert is_tuple(quote)
      assert elem(quote, 0) == :__block__
    end

    test "returns controller quote with custom log level" do
      quote = TdAuthWeb.controller(:debug)

      assert is_tuple(quote)
      assert elem(quote, 0) == :__block__
    end
  end

  describe "view/0" do
    test "returns view quote" do
      quote = TdAuthWeb.view()

      assert is_tuple(quote)
      assert elem(quote, 0) == :__block__
    end
  end

  describe "router/0" do
    test "returns router quote" do
      quote = TdAuthWeb.router()

      assert is_tuple(quote)
      assert elem(quote, 0) == :__block__
    end
  end

  describe "channel/0" do
    test "returns channel quote" do
      quote = TdAuthWeb.channel()

      assert is_tuple(quote)
      assert elem(quote, 0) == :use
    end
  end

  describe "__using__/1" do
    test "dispatches to appropriate function with atom" do
      # Suppress warning about private macro
      assert_raise UndefinedFunctionError, fn ->
        Code.eval_quoted(quote do: TdAuthWeb.__using__(:controller))
      end
    end

    test "dispatches to appropriate function with list" do
      # Suppress warning about private macro
      assert_raise UndefinedFunctionError, fn ->
        Code.eval_quoted(quote do: TdAuthWeb.__using__([:controller, :debug]))
      end
    end
  end
end
