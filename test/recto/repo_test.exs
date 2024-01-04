defmodule Recto.RepoTest do
  use ExUnit.Case

  require Recto.TestRepo, as: TestRepo

  @moduletag :capture_log

  defmodule MySchema do
    use Recto.Schema

    schema "my_schema" do
      field(:x, :string)
      field(:y, :boolean)
      field(:array, {:array, :string})
      field(:map, {:map, :string})
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
      assert {:ok, result} = TestRepo.smembers("key")
      assert Enum.sort(result, &(&1.x <= &2.x)) == [s, s2]
    end

    test "returns nil when no such key is specified" do
      assert TestRepo.smembers("no-such-key") == {:ok, []}
    end
  end

  describe "zadd" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      {:ok, %{schema: schema}}
    end

    test "add schema data to sorted set", %{schema: s} do
      assert TestRepo.zadd("key", 1, s) == {:ok, 1}
      assert TestRepo.zadd("key", 1, s) == {:ok, 0}
    end
  end

  describe "zrem" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      {:ok, %{schema: schema}}
    end

    test "remove schema data from sorted set", %{schema: s} do
      assert TestRepo.zrem("key", s) == {:ok, 1}
      assert TestRepo.zrem("key", s) == {:ok, 0}
    end
  end

  describe "zrank" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 2, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 3, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "returns the rank of member in the sorted set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrank("key", s) == {:ok, 0}
      assert TestRepo.zrank("key", s2) == {:ok, 1}
      assert TestRepo.zrank("key", s3) == {:ok, 2}
    end

    test "returns nil if member does not exist in the sorted set" do
      assert TestRepo.zrank("key", %MySchema{x: "unknown", y: true}) == {:ok, nil}
    end

    test "returns the rank of member and score in the sorted set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrank("key", s, withscore: true) == {:ok, [0, 1]}
      assert TestRepo.zrank("key", s2, withscore: true) == {:ok, [1, 2]}
      assert TestRepo.zrank("key", s3, withscore: true) == {:ok, [2, 3]}
    end
  end

  describe "zrevrank" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 2, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 3, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "returns the rank of member in the sorted set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrevrank("key", s) == {:ok, 2}
      assert TestRepo.zrevrank("key", s2) == {:ok, 1}
      assert TestRepo.zrevrank("key", s3) == {:ok, 0}
    end

    test "returns nil if member does not exist in the sorted set" do
      assert TestRepo.zrevrank("key", %MySchema{x: "unknown", y: true}) == {:ok, nil}
    end

    test "returns the rank of member and score in the sorted set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrevrank("key", s, withscore: true) == {:ok, [2, 1]}
      assert TestRepo.zrevrank("key", s2, withscore: true) == {:ok, [1, 2]}
      assert TestRepo.zrevrank("key", s3, withscore: true) == {:ok, [0, 3]}
    end
  end

  describe "zrange" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 2, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 3, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "returns the specified range of elements in the sorted set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrange("key", 0, 1) == {:ok, [s, s2]}
      assert TestRepo.zrange("key", 0, -1) == {:ok, [s, s2, s3]}
    end

    test "returns the specified range of elements in the sorted set stored at key with score", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrange("key", 0, 1, withscores: true) == {:ok, [[s, 1], [s2, 2]]}
      assert TestRepo.zrange("key", 0, -1, withscores: true) == {:ok, [[s, 1], [s2, 2], [s3, 3]]}
    end

    test "returns the reversed specified range of elements in the sorted set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zrange("key", 0, 1, rev: true) == {:ok, [s3, s2]}
      assert TestRepo.zrange("key", 0, 1, rev: true) == {:ok, [s3, s2]}
      assert TestRepo.zrange("key", 1, 2, withscores: true, rev: true) == {:ok, [[s2, 2], [s, 1]]}
    end

    test "returns the specified score range of elements in the stored set stored at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      s0 = %MySchema{x: "test0", y: true}
      TestRepo.zadd("key", 0, s0)
      assert TestRepo.zrange("key", 1, 3, byscore: true) == {:ok, [s, s2, s3]}
    end
  end

  describe "zremrangebyscore" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2", "key3"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 20, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 30, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "removes all elements in the sorted set stored at key with score between min and max", %{
      schema3: s3
    } do
      assert TestRepo.zremrangebyscore("key", 1, 20) == {:ok, 2}
      assert TestRepo.zrange("key", 0, -1) == {:ok, [s3]}
    end
  end

  describe "zremrangebyrank" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2", "key3"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 20, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 30, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "removes all elements in the sorted set stored at key with rank between start and stop",
         %{schema3: s3} do
      assert TestRepo.zremrangebyrank("key", 0, 1) == {:ok, 2}
      assert TestRepo.zrange("key", 0, -1) == {:ok, [s3]}
    end
  end

  describe "zscore" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2", "key3"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 20, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 30, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "returns the score of member in the sorted set at key", %{
      schema: s,
      schema2: s2,
      schema3: s3
    } do
      assert TestRepo.zscore("key", s) == {:ok, 1}
      assert TestRepo.zscore("key", s2) == {:ok, 20}
      assert TestRepo.zscore("key", s3) == {:ok, 30}
    end

    test "returns nil if member does not exist in the sorted set" do
      assert TestRepo.zscore("key", %MySchema{x: "unknown", y: true}) == {:ok, nil}
    end
  end

  describe "zincrby" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)

      {:ok, %{schema: schema}}
    end

    test "increments the score of member in the sorted set stored at key by increment", %{
      schema: s
    } do
      assert TestRepo.zincrby("key", 2, s) == {:ok, 3}
    end

    test "returns incremented score if member does not exist in the sorted set" do
      assert TestRepo.zincrby("key2", 2, %MySchema{x: "unknown", y: true}) == {:ok, 2}
    end
  end

  describe "zcount" do
    setup do
      on_exit(fn ->
        TestRepo.del(["key", "key2", "key3"])
      end)

      schema = %MySchema{x: "test", y: true}
      TestRepo.zadd("key", 1, schema)
      schema2 = %MySchema{x: "test2", y: true}
      TestRepo.zadd("key", 20, schema2)
      schema3 = %MySchema{x: "test3", y: true}
      TestRepo.zadd("key", 30, schema3)
      {:ok, %{schema: schema, schema2: schema2, schema3: schema3}}
    end

    test "returns the number of elements in the sorted set at key with a score between min and max" do
      assert TestRepo.zcount("key", 1, 20) == {:ok, 2}
      assert TestRepo.zcount("key", 1, 30) == {:ok, 3}
      assert TestRepo.zcount("key", 1, 40) == {:ok, 3}
    end
  end
end
