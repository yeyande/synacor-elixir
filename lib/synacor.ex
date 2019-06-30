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
    Map.update!(
      application,
      :registers,
      fn regs -> List.replace_at(regs, reg, val) end)
  end

  def _push(stack, val) do
    [val | stack]
  end

  def _pop(application, reg) do
    {top, new_state} = Map.get_and_update!(
      application,
      :stack,
      fn [top | rest] -> {top, rest} end
    )
    _set(new_state, reg, top)
  end

  def _out(io \\ IO, char) do
    io.write char
  end

  def _noop do
    :noop
  end
end
