defmodule Recto.Schema do
  @moduledoc false

  alias Recto.Schema.Metadata

  @doc false
  defmacro __using__(_) do
    quote do
      import Recto.Schema, only: [schema: 2]

      # TODO expiry_time
      @schema_version nil
      @timestamps_opts []
      Module.register_attribute(__MODULE__, :recto_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :recto_autogenerate, accumulate: true)
      Module.register_attribute(__MODULE__, :recto_autoupdate, accumulate: true)
    end
  end

  @field_opts [:default, :autogenerate]

  defmacro schema(source, do: block) do
    schema(__CALLER__, source, block)
  end

  defp schema(caller, source, block) do
    prelude =
      quote do
        if line = Module.get_attribute(__MODULE__, :recto_schema_defined) do
          raise "schema already defined for #{inspect(__MODULE__)} on line: #{line}"
        end

        @recto_schema_defined unquote(caller.line)

        # TODO after compile
        # @after_compile Recto.Schema
        Module.register_attribute(__MODULE__, :recto_struct_fields, accumulate: true)

        source = unquote(source)
        version = @schema_version

        # Fix warnings
        _ = @timestamps_opts

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

    postlude =
      quote unquote: false do
        autogenerate = @recto_autogenerate |> Enum.reverse()
        autoupdate = @recto_autoupdate |> Enum.reverse()
        fields = @recto_fields |> Enum.reverse()
        loaded = Recto.Schema.__loaded__(__MODULE__, @recto_struct_fields)

        defstruct Enum.reverse(@recto_struct_fields)

        def __schema__(:version), do: unquote(version)
        def __schema__(:source), do: unquote(Macro.escape(source))
        def __schema__(:autogenerate), do: unquote(Macro.escape(autogenerate))
        def __schema__(:autoupdate), do: unquote(Macro.escape(autoupdate))

        def __schema__(:autogenerate_fields),
          do: unquote(Enum.flat_map(autogenerate, &elem(&1, 0)))

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
      Recto.Schema.__meta__().version
    end
  end

  defmacro field(name, type \\ :string, opts \\ []) do
    quote do
      Recto.Schema.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  defmacro timestamps(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      Recto.Schema.__define_timestamps__(__MODULE__, Keyword.merge(@timestamps_opts, opts))
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

  @doc false
  def __define_timestamps__(mod, timestamps) do
    inserted_at = Keyword.get(timestamps, :inserted_at, :inserted_at)
    updated_at = Keyword.get(timestamps, :updated_at, :updated_at)
    type = :naive_datetime
    autogen = {Recto.Schema, :__timestamps__, [type]}

    if inserted_at do
      Recto.Schema.__field__(mod, inserted_at, type, [])
    end

    if updated_at do
      Recto.Schema.__field__(mod, updated_at, type, [])
      Module.put_attribute(mod, :recto_autoupdate, {[updated_at], autogen})
    end

    with [_ | _] = fields <- Enum.filter([inserted_at, updated_at], & &1) do
      Module.put_attribute(mod, :recto_autogenerate, {fields, autogen})
    end

    :ok
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

  # TODO: utc_datetime
  defp base_type?(atom),
    do: atom in [:integer, :string, :boolean, :any, :map, :array, :naive_datetime]

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
end
