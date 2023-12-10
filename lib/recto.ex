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

  def put_meta(%{__meta__: meta} = struct, opts) do
    case put_or_noop_meta(opts, meta, false) do
      :noop -> struct
      meta -> %{struct | __meta__: meta}
    end
  end

  defp put_or_noop_meta([{key, value} | t], meta, updated?) do
    case meta do
      %{^key => ^value} -> put_or_noop_meta(t, meta, updated?)
      _ -> put_or_noop_meta(t, put_meta(meta, key, value), true)
    end
  end

  defp put_or_noop_meta([], meta, true), do: meta
  defp put_or_noop_meta([], _meta, false), do: :noop

  defp put_meta(meta, :source, source) do
    %{meta | source: source}
  end

end
