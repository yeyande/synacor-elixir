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
  def _halt(system \\ System) do
    system.stop 0
  end

  def _set(registers, reg, val) do
    List.replace_at(registers, reg, val)
  end

  def _push(stack, val) do
    [val | stack]
  end

  def _pop(registers, stack, reg) do
    [top | rest] = stack
    {_set(registers, reg, top), rest}
  end

  def _out(io \\ IO, char) do
    io.write char
  end

  def _noop do
    :noop
  end
end
