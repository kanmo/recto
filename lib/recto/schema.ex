defmodule Recto.Schema do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote do
      import Recto.Schema, only: [schema: 1]

      @version 0
      @expiry_time nil

      Module.register_attribute(__MODULE__, :recto_fields, accumulate: true)
    end
  end

  defmacro schema(do: block) do
    schema(__CALLER__, block)
  end

  defp schema(caller, block) do
    prelude = quote do
      if line = Module.get_attribute(__MODULE__, :recto_schema_defined) do
        raise "schema already defined for #{inspect(__MODULE__)} on line: #{line}"
      end

      @recto_schema_defined unquote(caller.line)

      # TODO after compile
      # @after_compile Recto.Schema
      Module.register_attribute(__MODULE__, :recto_struct_fields, accumulate: true)

      # TODO put_attribute to save meta info

      try do
        import Recto.Schema
        unquote(block)
      after
        :ok
      end
    end

    postlude = quote unquote: false do
      fields = @recto_fields |> Enum.reverse()
      loaded = Recto.Schema.__loaded__(__MODULE__, @recto_struct_fields)

      defstruct Enum.reverse(@recto_struct_fields)

      def __schema__(:fields) do
        unquote(Enum.map(fields, &elem(&1, 0)))
      end

      def __schema__(:loaded) do
        unquote(Macro.escape(loaded))
      end

      for {args, body} <- Recto.Schema.__field_schema__(fields) do
        def __schema__(unquote_splicing(args)), do: unquote(body)
      end
    end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  ## API

  defmacro field(name, type \\ :string) do
    quote do
      Recto.Schema.__field__(__MODULE__, unquote(name), unquote(type))
    end
  end

  @doc false
  def __loaded__(mod, struct_fields) do
    case Map.new([{:__struct__, mod} | struct_fields]) do
      struct ->
        struct
    end
  end

  @doc false
  def __field__(mod, name, type) do
     type = check_field_type!(mod, name, type)

    define_field(mod, name, type)
  end

  # TODO source, assoc, embed
  @doc false
  def __field_schema__(fields) do
    for {name, type} <- fields do
      {[:type, name], Macro.escape(type)}
    end
  end

  defp define_field(mod, name, type) do
    fields = Module.get_attribute(mod, :recto_struct_fields)
    if List.keyfind(fields, name, 0) do
      raise ArgumentError,
            "field #{name} already defined for #{inspect(mod)}"
    end
    # TODO initial value
    Module.put_attribute(mod, :recto_struct_fields, {name, "initial value"})

    Module.put_attribute(mod, :recto_fields, {name, type})
  end

  defp check_field_type!(mod, name, type) do
    cond do
      composite?(type, name) ->
        {outer_type, inner_type} = type
        {outer_type, check_field_type!(mod, name, inner_type)}

      not is_atom(type) ->
        raise ArgumentError,
              "invalid type #{inspect(type)} for field #{inspect(name)}"

      base_type?(type) ->
        type

      # TODO module type
      #   Code.ensure_compiled(type) == {:module, type} ->

      true ->
        raise ArgumentError,
              "unknown type #{inspect(type)} for field #{inspect(name)}"
    end
  end


  defp base_type?(atom), do: atom in [:integer, :string, :boolean, :any, :map, :array]

  defp composite?({composite, _} = type, name) do
    if composite in [:array, :map] do
      true
    else
      raise ArgumentError,
            "invalid or unknown composite #{inspect(type)} for field #{inspect(name)}. " <>
            "Did you mean to use :array or :map as first element of the tuple instead?"
    end
  end

  defp composite?(_type, _name), do: false


  #defmacro version(number) do
  #  quote do
  #    Module.put_attribute(__MODULE__, :version, unquote(number))
  #  end
  #end


end