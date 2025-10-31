defmodule TdAuth.CustomSupervisorTest do
  use ExUnit.Case, async: true

  alias TdAuth.CustomSupervisor

  describe "start_link/1" do
    test "starts supervisor with proper configuration" do
      opts = %{children: [], strategy: :one_for_one}
      assert {:ok, pid} = CustomSupervisor.start_link(opts)
      assert is_pid(pid)
      assert Process.alive?(pid)
      Process.exit(pid, :normal)
    end

    test "starts supervisor with children" do
      children = [%{id: :test_child, start: {Agent, :start_link, [fn -> %{} end]}}]
      opts = %{children: children, strategy: :one_for_one}
      assert {:ok, pid} = CustomSupervisor.start_link(opts)
      assert is_pid(pid)
      assert Process.alive?(pid)
      Process.exit(pid, :normal)
    end
  end

  describe "init/1" do
    test "initializes supervisor with children and strategy" do
      children = [%{id: :test_child, start: {Agent, :start_link, [fn -> %{} end]}}]
      strategy = :one_for_one
      state = %{children: children, strategy: strategy}

      assert {:ok, _pid} = CustomSupervisor.init(state)
    end

    test "handles different strategies" do
      children = [%{id: :test_child, start: {Agent, :start_link, [fn -> %{} end]}}]
      strategies = [:one_for_one, :one_for_all, :rest_for_one]

      for strategy <- strategies do
        state = %{children: children, strategy: strategy}
        assert {:ok, supervisor_state} = CustomSupervisor.init(state)
        assert is_tuple(supervisor_state)
      end
    end

    test "handles empty children list" do
      children = []
      strategy = :one_for_one
      state = %{children: children, strategy: strategy}

      assert {:ok, supervisor_state} = CustomSupervisor.init(state)
      assert is_tuple(supervisor_state)
    end
  end
end
