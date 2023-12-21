defmodule Recto.RepoTest do
  use ExUnit.Case

  require Recto.TestRepo, as: TestRepo

  @moduletag :capture_log

  defmodule MySchema do
    use Recto.Schema

    schema "my_schema" do
      field :x, :string
      field :y, :boolean
      field :array, {:array, :string}
      field :map, {:map, :string}
    end
  end

  test "defines child_spec/1" do
    assert TestRepo.child_spec([]) == %{
             id: TestRepo,
             start: {TestRepo, :start_link, [[]]},
             type: :supervisor
           }
  end

  describe "set" do
    test "set schema data" do
      schema = %MySchema{x: "test", y: true, array: ["a", "r", "r", "a", "y"], map: %{key: "val"}}
      ## TODO autogenerate id
      assert TestRepo.set("key", schema) == {:ok, "OK"}
    end
  end

  describe "get" do
    setup do
      schema = %MySchema{x: "test", y: true, array: ["a", "r", "r", "a", "y"], map: %{key: "val"}}
      ## TODO autogenerate id
      TestRepo.set("key", schema)
      {:ok, %{schema: schema}}
    end

    test "get schema data", %{schema: s} do
      assert TestRepo.get(MySchema, "key") == {:ok, s}
    end
  end
end

