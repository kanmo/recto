defmodule Recto.Schema do
  @moduledoc false

  alias Recto.Schema.Metadata

  @doc false
  defmacro __using__(_) do
    quote do
      import Recto.Schema, only: [schema: 2]

      # TODO expiry_time
      @schema_version nil
      Module.register_attribute(__MODULE__, :recto_fields, accumulate: true)
    end
  end

  @field_opts [:default, :autogenerate]

  defmacro schema(source, do: block) do
    schema(__CALLER__, source, block)
  end

  defp schema(caller, source, block) do
    prelude = quote do
      if line = Module.get_attribute(__MODULE__, :recto_schema_defined) do
        raise "schema already defined for #{inspect(__MODULE__)} on line: #{line}"
      end

      @recto_schema_defined unquote(caller.line)

      # TODO after compile
      # @after_compile Recto.Schema
      Module.register_attribute(__MODULE__, :recto_struct_fields, accumulate: true)

      source = unquote(source)
      version = @schema_version

      meta = %Metadata{
        state: :built,
        source: source,
        version: version,
        schema: __MODULE__
      }

      Module.put_attribute(__MODULE__, :recto_struct_fields, {:__meta__, meta})

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

      def __schema__(:version), do: unquote(version)
      def __schema__(:source), do: unquote(Macro.escape(source))
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

  defmacro version() do
    quote do
      Recto.Schema.__meta__.version
    end
  end

  defmacro field(name, type \\ :string, opts \\ []) do
    quote do
      Recto.Schema.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  @doc false
  def __loaded__(mod, struct_fields) do
    case Map.new([{:__struct__, mod} | struct_fields]) do
      %{__meta__: meta} = struct ->
        %{struct | __meta__: Map.put(meta, :state, :loaded)}
      struct ->
        struct
    end
  end

  @doc false
  def __field__(mod, name, type, opts) do
     type = check_field_type!(mod, name, type)
     check_options!(type, opts, @field_opts, "field/3")

    define_field(mod, name, type, opts)
  end

  # TODO source, assoc, embed
  @doc false
  def __field_schema__(fields) do
    for {name, type} <- fields do
      {[:type, name], Macro.escape(type)}
    end
  end

  defp define_field(mod, name, type, opts) do
    fields = Module.get_attribute(mod, :recto_struct_fields)
    if List.keyfind(fields, name, 0) do
      raise ArgumentError,
            "field #{name} already defined for #{inspect(mod)}"
    end

    default_value = Keyword.get(opts, :default)
    Module.put_attribute(mod, :recto_struct_fields, {name, default_value})

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

      Code.ensure_compiled(type) == {:module, type} ->
        cond do
          function_exported?(type, :__schema__, 1) ->
            raise ArgumentError,
                  "schema #{inspect(type)} is not a valid type for field #{inspect(name)}."

          true ->
            type
        end

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

  defp check_options!(_type, opts, valid, fun_arity) do
    check_options!(opts, valid, fun_arity)
  end

  defp check_options!(opts, valid, fun_arity) do
    case Enum.find(opts, fn {k, _} -> k not in valid end) do
      nil ->
        :ok

      {k, _} ->
        raise ArgumentError,
              "invalid option #{inspect(k)} for #{fun_arity}"
    end
  end



  #defmacro version(number) do
  #  quote do
  #    Module.put_attribute(__MODULE__, :version, unquote(number))
  #  end
  #end


end