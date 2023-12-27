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

  describe "sadd" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      {:ok, %{schema: schema}}
    end

    test "add schema data to set", %{schema: s} do
      assert TestRepo.sadd("key", s) == {:ok, 1}
      assert TestRepo.sadd("key", s) == {:ok, 0}
    end
  end

  describe "srem" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.sadd("key", schema)
      {:ok, %{schema: schema}}
    end

    test "remove schema data from set", %{schema: s} do
      assert TestRepo.srem("key", s) == {:ok, 1}
      assert TestRepo.srem("key", s) == {:ok, 0}
    end
  end

  describe "sismember" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.sadd("key", schema)
      {:ok, %{schema: schema}}
    end

    test "returns true if schema data is a member of set", %{schema: s} do
      assert TestRepo.sismember("key", s) == {:ok, true}
    end

    test "returns false if schema data is not a member of set" do
      assert TestRepo.sismember("key", %MySchema{x: "test2", y: true}) == {:ok, false}
    end
  end

  describe "scard" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.sadd("key", schema)
      {:ok, %{schema: schema}}
    end

    test "returns the set cardinality (number of elements) of the set stored at key" do
      assert TestRepo.scard("key") == {:ok, 1}
    end

    test "returns zero if key does not exist" do
      assert TestRepo.scard("no-such-key") == {:ok, 0}
    end

  end

  describe "smembers" do
    # Test Repo.smembers
    setup do
      on_exit(fn ->
        TestRepo.del(["key"])
      end)

      schema = %MySchema{x: "test", y: true}
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.sadd("key", schema)
      TestRepo.sadd("key", schema2)
      {:ok, %{schema: schema, schema2: schema2}}
    end

    test "returns all members of the set value stored at key", %{schema: s, schema2: s2} do
      assert TestRepo.smembers("key") == {:ok, [s, s2]}
    end

    test "returns nil when no such key is specified" do
      assert TestRepo.smembers("no-such-key") == {:ok, []}
    end
  end
end































