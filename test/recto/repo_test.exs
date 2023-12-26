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
    setup do
      on_exit(fn ->
        TestRepo.del("key")
      end)
    end

    test "set schema data" do
      schema = %MySchema{x: "test", y: true, array: ["a", "r", "r", "a", "y"], map: %{key: "val"}}
      ## TODO autogenerate id
      assert TestRepo.set("key", schema) == {:ok, "OK"}
    end
  end

  describe "get" do
    setup do
      on_exit(fn ->
        TestRepo.del("key")
      end)

      schema = %MySchema{x: "test", y: true, array: ["a", "r", "r", "a", "y"], map: %{key: "val"}}
      ## TODO autogenerate id
      TestRepo.set("key", schema)
      {:ok, %{schema: schema}}
    end

    test "get schema data", %{schema: s} do
      assert TestRepo.get("key") == {:ok, s}
    end

    test "returns nil when no such key is specified" do
      assert TestRepo.get("unknown") == {:ok, nil}
    end
  end

  describe "expire" do
    setup do
      on_exit(fn ->
        TestRepo.del("key")
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.set("key", schema)
      {:ok, %{schema: schema}}
    end

    test "expire schema data", %{schema: _s} do
      assert TestRepo.expire("key", 0) == :ok
      assert TestRepo.get("key") == {:ok, nil}
    end
  end

  describe "exists" do
    setup do
      on_exit(fn ->
        TestRepo.del("key")
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.set("key", schema)
      {:ok, %{schema: schema}}
    end

    test "returns exists count when data exists", %{schema: _s} do
      assert TestRepo.exists("key") == {:ok, 1}
      TestRepo.set("key2", %MySchema{x: "test2", y: true})
      assert TestRepo.exists(["key", "key2"]) == {:ok, 2}
    end

    test "returns zero when data does not exist" do
      assert TestRepo.exists("no-such-key") == {:ok, 0}
    end
  end

  describe "del" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.set("key", schema)
      {:ok, %{schema: schema}}
    end

    test "del specified key data", %{schema: _s} do
      assert TestRepo.del("key") == {:ok, 1}
      TestRepo.set("key", %MySchema{x: "test", y: true})
      TestRepo.set("key2", %MySchema{x: "test2", y: true})
      assert TestRepo.del(["key", "key2"]) == {:ok, 2}
    end
  end

  describe "rpush" do
    setup do
      on_exit(fn ->
        TestRepo.del("key")
      end)
    end

    test "enqueue data by using rpush" do
      schema = %MySchema{x: "test", y: true}
      assert TestRepo.rpush("key", schema) == {:ok, 1}
    end
  end

  describe "lpop" do
    setup do
      on_exit(fn ->
        TestRepo.del("key")
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.rpush("key", schema)
      {:ok, %{schema: schema}}
    end

    test "dequeue data by using lpop", %{schema: s} do
      assert TestRepo.lpop("key") == {:ok, s}
    end

    test "returns nil when no such key is specified" do
      assert TestRepo.lpop("no-such-key") == {:ok, nil}
    end
  end

  describe "lrange" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2", "key3"])
      end)

      schema = %MySchema{x: "test", y: true}
      schema2 = %MySchema{x: "test2", y: true}
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.rpush("key", schema)
      TestRepo.rpush("key", schema2)
      TestRepo.rpush("key", schema3)

      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "dequeue multiple data", %{schema: s, schema2: s2, schema3: s3} do
      assert TestRepo.lrange("key", 0, 1) == {:ok, [s, s2]}
      assert TestRepo.lrange("key", 0, -1) == {:ok, [s, s2, s3]}
    end
  end
end































