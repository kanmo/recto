defmodule Recto.Schema.Metadata do
  @moduledoc false

  defstruct [:source, :schema, :version, :state]

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(metadata, opts) do
      %{source: source, version: version, state: state} = metadata

      entries =
        for entry <- [state, source, version],
            entry != nil,
            do: to_doc(entry, opts)

      concat(["#Recto.Schema.Metadata<"] ++ Enum.intersperse(entries, ", ") ++ [">"])
    end
  end
end
