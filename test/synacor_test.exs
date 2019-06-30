defmodule SynacorTest do
  use ExUnit.Case
  doctest Synacor

  defmodule FakeSystem do
    def stop(0), do: :stop
  end

  defmodule FakeIO do
    def write('c'), do: :ok
  end

  test "should give proper initialization state" do
    assert Synacor.init_vm() == %{
      registers: List.duplicate(0, 8),
      stack: []
    }
  end

  test "should stop application" do
    assert Synacor._halt(FakeSystem) == :stop
  end

  test "should set a register" do
    state = %{
      registers: [1, 2, 3, 4, 5, 6, 7, 8],
      stack: []
    }
    assert Synacor._set(state, 3, 254) == %{
      registers: [1, 2, 3, 254, 5, 6, 7, 8],
      stack: []
    }
  end

  test "should push onto the stack" do
    state = %{
      registers: [1, 2, 3, 4, 5, 6, 7, 8],
      stack: [1, 2, 3]
    }
    assert Synacor._push(state, 4) == %{
      registers: [1, 2, 3, 4, 5, 6, 7, 8],
      stack: [4, 1, 2, 3]
    }
  end

  test "should pop stack value into register" do
    state = %{
      registers: [1, 2, 3, 4, 5, 6, 7, 8],
      stack: [1, 2, 3]
    }
    assert Synacor._pop(state, 1) == %{
      registers: [1, 1, 3, 4, 5, 6, 7, 8],
      stack: [2, 3]
    }
  end

  test "should print a character" do
    assert Synacor._out(FakeIO, 'c') == :ok
  end

  test "should not do anything" do
    assert Synacor._noop() == :noop
  end

end
