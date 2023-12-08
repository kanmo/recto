defmodule Recto.SchemaTest do
  use ExUnit.Case

  defmodule Schema do
    use Recto.Schema

    schema do
      field :id,  :integer
      field :name, :string, default: "fruit"
      field :age, :integer
      field :array, {:array, :string}
      field :map, {:map, :any}
    end
  end

#  @moduletag :capture_log

#  doctest Schema

  test "schema metadata" do
    assert Schema.__schema__(:fields) == [:id, :name, :age, :array, :map]
  end

  test "types metadata" do
    assert Schema.__schema__(:type, :id) == :integer
    assert Schema.__schema__(:type, :name) == :string
    assert Schema.__schema__(:type, :age) == :integer
    assert Schema.__schema__(:type, :array) == {:array, :string}
    assert Schema.__schema__(:type, :map) == {:map, :any}
  end

  test "schema attributes" do
    schema = %Schema{id: 1, name: "John", age: 30, array: ["a", "b", "c"], map: %{a: 1, b: 2, c: 3}}
    assert schema.id == 1
    assert schema.name == "John"
    assert schema.age == 30
    assert schema.array == ["a", "b", "c"]
    assert schema.map == %{a: 1, b: 2, c: 3}
  end

  test "default value" do
    assert %Schema{}.name == "fruit"
  end


  defmodule DataValue do
    defstruct [:id, :name]
  end

  defmodule ModuleSetSchema do
    use Recto.Schema

    schema do
      field :data, DataValue
    end
  end

  test "set module value" do
    data = %ModuleSetSchema{data: %DataValue{id: 1, name: "Toji"}}
    assert data.data == %DataValue{id: 1, name: "Toji"}
  end

  test "invalid field type" do
    assert_raise ArgumentError, "invalid type {:nappa} for field :name", fn ->
      defmodule SchemaInvalidFieldType do
        use Recto.Schema

        schema do
          field :name, {:nappa}
        end
      end
    end

    assert_raise ArgumentError, "unknown type OMG for field :name", fn ->
      defmodule SchemaUnknownType do
        use Recto.Schema

        schema do
          field :name, OMG
        end
      end
    end

    assert_raise ArgumentError,
~r/schema Recto.SchemaTest.Schema is not a valid type for field :name/,
    fn ->
                   defmodule SchemaInvalidFieldType do
                     use Recto.Schema

                     schema do
                       field :name, Schema
                     end
                   end
                 end

    assert_raise ArgumentError, "unknown type :jsonb for field :name", fn ->
      defmodule SchemaInvalidFieldType do
        use Recto.Schema

        schema do
          field :name, :jsonb
        end
      end
    end

    assert_raise ArgumentError, "unknown type :jsonb for field :name", fn ->
      defmodule SchemaInvalidFieldType do
        use Recto.Schema

        schema do
          field :name, {:array, :jsonb}
        end
      end
    end
  end


  test "invalid option for field" do
    assert_raise ArgumentError, ~s/invalid option :starts_on for field\/3/, fn ->
      defmodule SchemaInvalidOption do
        use Recto.Schema

        schema do
          field :count, :integer, starts_on: 3
        end
      end
    end
  end
end

