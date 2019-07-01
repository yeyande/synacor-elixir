defmodule Synacor do
  use Bitwise
  @moduledoc """
  Documentation for Synacor.
  """

  @doc """
  Hello world.

  ## Examples

      iex> import ExUnit.CaptureIO
      iex> capture_io(fn -> Synacor._out(%{}, 'c') end)
      "c"

      iex> Synacor._noop(%{})
      %{}

  """
  def init_vm do
    %{
      registers: List.duplicate(0, :math.pow(2,16) |> round),
      stack: [],
      pc: 0
    }
  end

  def _halt(system \\ System) do
    system.stop 0
  end

  def _set(application, reg, val) do
    Map.update!(
      application,
      :registers,
      fn regs -> List.replace_at(regs, reg, val) end)
  end

  def _push(application, val) do
    Map.update!(
      application,
      :stack,
      fn stack -> [val | stack] end
    )
  end

  def _pop(application, reg) do
    try do
      {top, new_state} = Map.get_and_update!(
        application,
        :stack,
        fn [top | rest] -> {top, rest} end
      )
      _set(new_state, reg, top)
    rescue
      FunctionClauseError -> raise "Cannot pop from empty stack"
    end
  end

  defp get_register(application, reg) do
    Map.fetch!(application, :registers) |> Enum.at(reg)
  end

  defp compare_registers(application, operator, a, b) do
    val1 = get_register(application, a)
    val2 = get_register(application, b)
    case operator.(val1, val2) do
      true -> 1
      false -> 0
    end
  end

  def _eq(application, out, a, b) do
    _set(application, out, compare_registers(application, &Kernel.==/2, a, b))
  end

  def _gt(application, out, a, b) do
    _set(application, out, compare_registers(application, &Kernel.>/2, a, b))
  end

  def _jmp(application, loc) do
    Map.replace!(application, :pc, loc)
  end

  def _jt(application, reg, loc) do
    Map.update!(
      application,
      :pc,
      fn pc -> if get_register(application, reg) != 0, do: loc, else: pc end
    )
  end

  def _jf(application, reg, loc) do
    Map.update!(
      application,
      :pc,
      fn pc -> if get_register(application, reg) == 0, do: loc, else: pc end
    )
  end

  def _add(application, out, a, b) do
    application |> _set(out, rem(a+b, 32768))
  end

  def _mult(application, out, a, b) do
    application |> _set(out, rem(a*b, 32768))
  end

  def _mod(application, out, a, b) do
    application |> _set(out, rem(a, b))
  end

  def _and(application, out, a, b) do
    application |> _set(out, a &&& b)
  end

  def _or(application, out, a, b) do
    application |> _set(out, a ||| b)
  end

  def _not(application, out, a) do
    << _::1, x::15 >>= <<Bitwise.bnot(a)::16 >>
    application |> _set(out, x)
  end

  def _rmem(application, out, loc) do
    application |> _set(out, get_register(application, loc))
  end

  def _wmem(application, out, a) do
    application |> _set(out, a)
  end

  defp get_next_instruction(application) do
    Map.update!(application, :pc, fn pc -> pc + 1 end)
  end

  def _call(application, loc) do
    next_pc = application |> get_next_instruction
    new_state = application |> _push(Map.fetch!(next_pc, :pc))
    new_state |> _jmp(loc)
  end

  def _ret(system \\ System, application) do
    try do
      old_regs = application |> Map.fetch!(:registers)
      popped = application |> _pop(0) 
      loc = popped |> Map.fetch!(:registers) |> Enum.at(0)
      popped |> Map.replace!(:registers, old_regs) |> _jmp(loc)
    rescue
      RuntimeError -> _halt system
    end
  end

  def _out(io \\ IO, application, char) do
    io.write char
    application
  end

  def _in(io \\ IO, application, out) do
    input = io.gets("") |> String.trim |> String.to_charlist
    registers = application |> Map.fetch!(:registers)
    {new_registers, _} = input |> List.foldl(
      {registers, out},
      fn char, {acc, inc} -> {List.replace_at(acc, inc, char), inc+1} end)
    application |> Map.replace!(:registers, new_registers)
  end

  def _noop(application) do
    application
  end
end
