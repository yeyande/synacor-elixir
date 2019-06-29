defmodule Synacor do
  @moduledoc """
  Documentation for Synacor.
  """

  @doc """
  Hello world.

  ## Examples

      iex> import ExUnit.CaptureIO
      iex> capture_io(fn -> Synacor._out('c') end)
      "c"

      iex> Synacor._noop
      :noop

  """
  def init_vm do
    %{
      registers: List.duplicate(0, 8),
      stack: []
    }
  end

  def _halt(system \\ System) do
    system.stop 0
  end

  def _set(application, reg, val) do
    new_registers = List.replace_at(
                      Map.fetch!(application, :registers), reg, val)
    Map.replace!(application, :registers, new_registers)
  end

  def _push(stack, val) do
    [val | stack]
  end

  def _pop(application, reg) do
    [top | rest] = Map.fetch!(application, :stack)
    new_state = Map.replace!(application, :stack, rest)
    _set(new_state, reg, top)
  end

  def _out(io \\ IO, char) do
    io.write char
  end

  def _noop do
    :noop
  end
end
