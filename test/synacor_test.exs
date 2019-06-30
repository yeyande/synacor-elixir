defmodule SynacorTest do
  use ExUnit.Case
  doctest Synacor

  defmodule FakeSystem do
    def stop(0), do: :stop
  end

  defmodule FakeIO do
    def write('c'), do: :ok
  end

  @base_state %{
      registers: List.duplicate(0, 8),
      stack: []
  }

  test "should give proper initialization state" do
    assert Synacor.init_vm() == @base_state
  end

  test "should stop application" do
    assert Synacor._halt(FakeSystem) == :stop
  end

  test "should set a register" do
    assert Synacor._set(@base_state, 3, 254) == Map.replace!(
      @base_state,
      :registers, 
      [0, 0, 0, 254, 0, 0, 0, 0]
    )
  end

  describe "stack operations" do 
    test "should push onto the stack" do
      state = Map.replace!(@base_state, :stack, [1, 2, 3])
      assert Synacor._push(state, 4) == Map.replace!(
        @base_state,
        :stack,
        [4, 1, 2, 3]
      )
    end

    test "should pop stack value into register" do
      state = Map.replace!(@base_state, :stack, [1, 2, 3])
      assert Synacor._pop(state, 1) == Map.merge(
        state,
        %{
          registers: [0, 1, 0, 0, 0, 0, 0, 0],
          stack: [2, 3]
        }
      )
    end

    test "should throw error when popping from an empty stack" do
      assert_raise RuntimeError,
                   "Cannot pop from empty stack",
                   fn -> Synacor._pop(@base_state, 1) end
    end
  end

  test "should print a character" do
    assert Synacor._out(FakeIO, @base_state, 'c') == @base_state
  end

  test "should not do anything" do
    assert Synacor._noop(@base_state) == @base_state
  end

end
