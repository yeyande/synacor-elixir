defmodule SynacorTest do
  use ExUnit.Case
  doctest Synacor

  defmodule FakeSystem do
    def stop(0), do: :stop
  end

  defmodule FakeIO do
    def write('c'), do: :ok
    def gets(""), do: "abc\n"
  end

  @base_state %{
    registers: List.duplicate(0, :math.pow(2,16) |> round),
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
    memory = [0, 0, 0, 254]
    {_, tail } = @base_state |> Map.fetch!(:registers) |> Enum.split(4)
    assert Synacor._set(@base_state, 3, 254) == Map.replace!(
      @base_state,
      :registers, 
      memory ++ tail
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
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(1, 1)
      state = Map.replace!(@base_state, :stack, [1, 2, 3])
      assert Synacor._pop(state, 1) == Map.merge(
        state,
        %{
          registers: registers,
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
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(1, 1)
      assert Synacor._eq(@base_state, 1, 0, 2) == Map.replace!(
        @base_state,
        :registers, 
        registers
      )
    end

    test "should set register 1 to 0 when not equal" do
      {_, tail} = @base_state |> Map.fetch!(:registers) |> Enum.split(3)
      state = Map.replace!(
        @base_state,
        :registers,
        [1, 1, 3 | tail]
      )
      assert Synacor._eq(state, 1, 0, 2) == Map.replace!(
        state,
        :registers, 
        [1, 0, 3 | tail]
      )
    end

    test "should set register to 1 to 1 when greater than" do
      {_, tail} = @base_state |> Map.fetch!(:registers) |> Enum.split(3)
      state = Map.replace!(
        @base_state,
        :registers,
        [2, 0, 1 | tail]
      )
      assert Synacor._gt(state, 1, 0, 2) == Map.replace!(
        state,
        :registers, 
        [2, 1, 1 | tail]
      )
    end

    test "should set register to 1 to 0 when less than" do
      {_, tail} = @base_state |> Map.fetch!(:registers) |> Enum.split(3)
      state = Map.replace!(
        @base_state,
        :registers,
        [2, 0, 1 | tail]
      )
      assert Synacor._gt(state, 1, 2, 0) == Map.replace!(
        state,
        :registers, 
        [2, 0, 1 | tail]
      )
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
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 2)
      state = Map.replace!(@base_state,
        :registers,
        registers
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
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 2)
      state = Map.replace!(@base_state,
        :registers,
        registers
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
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 4)
      assert Synacor._add(@base_state, 0, 1, 3) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end

    test "add should overflow over 32768" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 5)
      assert Synacor._add(@base_state, 0, 32758, 15) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end

    test "should multiply two numbers" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 6)
      assert Synacor._mult(@base_state, 0, 2, 3) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end

    test "multiply should overflow two numbers over 32768" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 32)
      assert Synacor._mult(@base_state, 0, 2, 16400) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end

    test "modulo operation should return 5" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 2)
      assert Synacor._mod(@base_state, 0, 2, 5) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end
  end

  describe "bitwise operations" do
    test "and 3 and 2 should be 2" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 2)
      assert Synacor._and(@base_state, 0, 3, 2) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end

    test "or 4 and 2 should be 6" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 6)
      assert Synacor._or(@base_state, 0, 4, 2) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end

    test "not 4 should be 32763" do
      registers = @base_state |> Map.fetch!(:registers) |> List.replace_at(0, 32763)
      assert Synacor._not(@base_state, 0, 4) == Map.replace!(
        @base_state,
        :registers,
        registers
      )
    end
  end

  describe "memory operations" do
    test "read should store 4 into register 0" do
      {_, tail} = @base_state |> Map.fetch!(:registers) |> Enum.split(3)
      state = Map.replace!(
        @base_state,
        :registers,
        [0, 0, 4 | tail]
      )
      assert Synacor._rmem(state, 0, 2) == Map.replace!(
        state,
        :registers,
        [4, 0, 4 | tail]
      )
    end

    test "write should store 500 into register 0" do
      {_, tail} = @base_state |> Map.fetch!(:registers) |> Enum.split(3)
      state = Map.replace!(
        @base_state,
        :registers,
        [0, 0, 4 | tail]
      )
      assert Synacor._wmem(state, 0, 500) == Map.replace!(
        state,
        :registers,
        [500, 0, 4 | tail]
      )
    end
  end

  test "call should push next instruction onto the stack and jump" do
    assert Synacor._call(@base_state, 500) == Map.merge(
      @base_state,
      %{ pc: 500, stack: [1] }
    )
  end

  test "ret should set the pc to the value at the top of the stack" do
    state = @base_state |> Map.replace!(:stack, [100])
    assert Synacor._ret(state) == @base_state |> Map.replace!(:pc, 100)
  end

  test "ret should halt with an empty stack" do
    assert Synacor._ret(FakeSystem, @base_state) == :stop
  end

  test "should print a character" do
    assert Synacor._out(FakeIO, @base_state, 'c') == @base_state
  end

  test "should copy input into memory" do
    {_, tail} = @base_state |> Map.fetch!(:registers) |> Enum.split(3)
    assert Synacor._in(FakeIO, @base_state, 0) == @base_state |> Map.replace!(
      :registers,
      [97, 98, 99 | tail]
    )
  end

  test "should not do anything" do
    assert Synacor._noop(@base_state) == @base_state
  end

end
