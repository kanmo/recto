defmodule Recto do
  @moduledoc """
  Documentation for `Recto`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Recto.hello()
      :world

  """
  def repo() do
    Application.get_env(:recto, :repo)
  end
end
