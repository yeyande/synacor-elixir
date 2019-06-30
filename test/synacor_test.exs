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
    stack: [],
    pc: 0
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

  describe "equality operations" do
    test "should set register 1 to 1 when equal" do
      assert Synacor._eq(@base_state, 1, 0, 2) == Map.replace!(
        @base_state,
        :registers, 
        [0, 1, 0, 0, 0, 0, 0, 0])
    end

    test "should set register 1 to 0 when not equal" do
      state = Map.replace!(
        @base_state,
        :registers,
        [1, 1, 3, 0, 0, 0, 0, 0])
      assert Synacor._eq(state, 1, 0, 2) == Map.replace!(
        state,
        :registers, 
        [1, 0, 3, 0, 0, 0, 0, 0])
    end

    test "should set register to 1 to 1 when greater than" do
      state = Map.replace!(
        @base_state,
        :registers,
        [2, 0, 1, 0, 0, 0, 0, 0])
      assert Synacor._gt(state, 1, 0, 2) == Map.replace!(
        state,
        :registers, 
        [2, 1, 1, 0, 0, 0, 0, 0])
    end

    test "should set register to 1 to 0 when less than" do
      state = Map.replace!(
        @base_state,
        :registers,
        [2, 0, 1, 0, 0, 0, 0, 0])
      assert Synacor._gt(state, 1, 2, 0) == Map.replace!(
        state,
        :registers, 
        [2, 0, 1, 0, 0, 0, 0, 0])
    end

    test "should set register 1 to 0 when equal" do
      assert Synacor._gt(@base_state, 1, 0, 2) == @base_state
    end
  end

  describe "jump operations" do
    test "should set program counter to jump value" do
      assert Synacor._jmp(@base_state, 2) == Map.replace!(
        @base_state,
        :pc,
        2
      )
    end

    test "jt should jump when address is nonzero" do
      state = Map.replace!(@base_state,
        :registers,
        [2, 0, 0, 0, 0, 0, 0, 0]
      )
      assert Synacor._jt(state, 0, 5) == Map.replace!(
        state,
        :pc,
        5
      )
    end

    test "jt should not jump when address is zero" do
      assert Synacor._jt(@base_state, 0, 5) == @base_state
    end

    test "jf should not jump when address is nonzero" do
      state = Map.replace!(@base_state,
        :registers,
        [2, 0, 0, 0, 0, 0, 0, 0]
      )
      assert Synacor._jf(state, 0, 5) == state
    end

    test "jf should jump when address is zero" do
      assert Synacor._jf(@base_state, 0, 5) == Map.replace!(
        @base_state,
        :pc,
        5
      )
    end
  end

  describe "math operations" do
    test "should add two numbers" do
      assert Synacor._add(@base_state, 0, 1, 3) == Map.replace!(
        @base_state,
        :registers,
        [4, 0, 0, 0, 0, 0, 0, 0]
      )
    end

    test "add should overflow over 32768" do
      assert Synacor._add(@base_state, 0, 32758, 15) == Map.replace!(
        @base_state,
        :registers,
        [5, 0, 0, 0, 0, 0, 0 ,0]
      )
    end

    test "should multiply two numbers" do
      assert Synacor._mult(@base_state, 0, 2, 3) == Map.replace!(
        @base_state,
        :registers,
        [6, 0, 0, 0, 0, 0, 0, 0]
      )
    end

    test "multiply should overflow two numbers over 32768" do
      assert Synacor._mult(@base_state, 0, 2, 16400) == Map.replace!(
        @base_state,
        :registers,
        [32, 0, 0, 0, 0, 0, 0, 0]
      )
    end

    test "modulo operation should return 5" do
      assert Synacor._mod(@base_state, 0, 2, 5) == Map.replace!(
        @base_state,
        :registers,
        [2, 0, 0, 0, 0, 0, 0, 0]
      )
    end
  end

  describe "bitwise operations" do
    test "and 3 and 2 should be 2" do
      assert Synacor._and(@base_state, 0, 3, 2) == Map.replace!(
        @base_state,
        :registers,
        [2, 0, 0, 0, 0, 0, 0, 0]
      )
    end
  end

  test "should print a character" do
    assert Synacor._out(FakeIO, @base_state, 'c') == @base_state
  end

  test "should not do anything" do
    assert Synacor._noop(@base_state) == @base_state
  end

end
