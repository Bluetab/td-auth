defmodule TdAuth.Map.HelpersTest do
  use ExUnit.Case, async: true

  alias TdAuth.Map.Helpers

  describe "underscore_keys/1" do
    test "converts camelCase keys to underscore_keys" do
      input = %{"firstName" => "John", "lastName" => "Doe"}
      expected = %{"first_name" => "John", "last_name" => "Doe"}

      assert expected == Helpers.underscore_keys(input)
    end

    test "converts kebab-case keys to underscore_keys" do
      input = %{"first-name" => "John", "last-name" => "Doe"}
      expected = %{"first_name" => "John", "last_name" => "Doe"}

      assert expected == Helpers.underscore_keys(input)
    end

    test "handles nested maps" do
      input = %{"user" => %{"firstName" => "John", "lastName" => "Doe"}}
      expected = %{"user" => %{"first_name" => "John", "last_name" => "Doe"}}

      assert expected == Helpers.underscore_keys(input)
    end

    test "handles lists of maps" do
      input = [%{"firstName" => "John"}, %{"lastName" => "Doe"}]
      expected = [%{"first_name" => "John"}, %{"last_name" => "Doe"}]

      assert expected == Helpers.underscore_keys(input)
    end

    test "handles nil input" do
      assert nil == Helpers.underscore_keys(nil)
    end

    test "handles non-map input" do
      assert "string" == Helpers.underscore_keys("string")
      assert 123 == Helpers.underscore_keys(123)
      assert true == Helpers.underscore_keys(true)
    end

    test "handles empty map" do
      assert %{} == Helpers.underscore_keys(%{})
    end
  end

  describe "atomize_keys/1" do
    test "converts string keys to atom keys" do
      input = %{"name" => "John", "age" => 30}
      expected = %{name: "John", age: 30}

      assert expected == Helpers.atomize_keys(input)
    end

    test "handles nested maps" do
      input = %{"user" => %{"name" => "John", "age" => 30}}
      expected = %{user: %{name: "John", age: 30}}

      assert expected == Helpers.atomize_keys(input)
    end

    test "handles lists of maps" do
      input = [%{"name" => "John"}, %{"age" => 30}]
      expected = [%{name: "John"}, %{age: 30}]

      assert expected == Helpers.atomize_keys(input)
    end

    test "handles nil input" do
      assert nil == Helpers.atomize_keys(nil)
    end

    test "handles non-map input" do
      assert "string" == Helpers.atomize_keys("string")
      assert 123 == Helpers.atomize_keys(123)
      assert true == Helpers.atomize_keys(true)
    end

    test "handles structs" do
      struct = %{__struct__: MyStruct, field: "value"}
      assert struct == Helpers.atomize_keys(struct)
    end

    test "handles empty map" do
      assert %{} == Helpers.atomize_keys(%{})
    end
  end

  describe "stringify_keys/1" do
    test "converts atom keys to string keys" do
      input = %{name: "John", age: 30}
      expected = %{"name" => "John", "age" => 30}

      assert expected == Helpers.stringify_keys(input)
    end

    test "handles mixed key types" do
      input = %{name: "John", age: 30, status: "active"}
      expected = %{"name" => "John", "age" => 30, "status" => "active"}

      assert expected == Helpers.stringify_keys(input)
    end

    test "handles nested maps" do
      input = %{user: %{name: "John", age: 30}}
      expected = %{"user" => %{"name" => "John", "age" => 30}}

      assert expected == Helpers.stringify_keys(input)
    end

    test "handles lists of maps" do
      input = [%{name: "John"}, %{age: 30}]
      expected = [%{"name" => "John"}, %{"age" => 30}]

      assert expected == Helpers.stringify_keys(input)
    end

    test "handles nil input" do
      assert nil == Helpers.stringify_keys(nil)
    end

    test "handles non-map input" do
      assert "string" == Helpers.stringify_keys("string")
      assert 123 == Helpers.stringify_keys(123)
      assert true == Helpers.stringify_keys(true)
    end

    test "handles empty map" do
      assert %{} == Helpers.stringify_keys(%{})
    end
  end

  describe "deep_merge/2" do
    test "merges two maps" do
      left = %{a: 1, b: 2}
      right = %{b: 3, c: 4}
      expected = %{a: 1, b: 3, c: 4}

      assert expected == Helpers.deep_merge(left, right)
    end

    test "merges nested maps" do
      left = %{user: %{name: "John", age: 30}}
      right = %{user: %{age: 31, city: "NYC"}}
      expected = %{user: %{name: "John", age: 31, city: "NYC"}}

      assert expected == Helpers.deep_merge(left, right)
    end

    test "handles empty maps" do
      left = %{}
      right = %{a: 1}
      expected = %{a: 1}

      assert expected == Helpers.deep_merge(left, right)
    end

    test "handles nil values" do
      left = %{a: 1}
      right = %{a: nil}
      expected = %{a: nil}

      assert expected == Helpers.deep_merge(left, right)
    end

    test "prefers right value for non-map values" do
      left = %{a: %{b: 1}}
      right = %{a: "string"}
      expected = %{a: "string"}

      assert expected == Helpers.deep_merge(left, right)
    end
  end

  describe "to_map/1" do
    test "converts keyword list to map" do
      input = [name: "John", age: 30]
      expected = %{name: "John", age: 30}

      assert expected == Helpers.to_map(input)
    end

    test "converts nested keyword list to map" do
      input = [user: [name: "John", age: 30], status: "active"]
      expected = %{user: %{name: "John", age: 30}, status: "active"}

      assert expected == Helpers.to_map(input)
    end

    test "handles empty keyword list" do
      assert %{} == Helpers.to_map([])
    end

    test "handles non-list input" do
      assert "string" == Helpers.to_map("string")
      assert 123 == Helpers.to_map(123)
      assert true == Helpers.to_map(true)
    end

    test "handles mixed types in keyword list" do
      input = [name: "John", age: 30, active: true, data: [key: "value"]]
      expected = %{name: "John", age: 30, active: true, data: %{key: "value"}}

      assert expected == Helpers.to_map(input)
    end
  end
end
