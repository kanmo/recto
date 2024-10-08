defmodule Recto.Query do
  @moduledoc false

  # List

  def to_rpush_query(key, value), do: ["RPUSH", key, value]
  def to_lpop_query(key), do: ["LPOP", key]
  def to_lrange_query(key, start, stop), do: ["LRANGE", key, start, stop]
  def to_llen_query(key), do: ["LLEN", key]
  def to_ltrim_query(key, start, stop), do: ["LTRIM", key, start, stop]

  # String

  @set_options ~w(EX NX XX)a

  def to_set_query(key, value, opts \\ []) do
    Recto.Query.check_options!(opts, @set_options, "Binary.to_set_query/3")
    create_query(opts, ["SET", key, value])
  end

  def to_get_query(key), do: ["GET", key]

  # Set

  def to_smembers_query(key), do: ["SMEMBERS", key]
  def to_sadd_query(key, value), do: ["SADD", key, value]
  def to_srem_query(key, value), do: ["SREM", key, value]
  def to_sismember_query(key, value), do: ["SISMEMBER", key, value]
  def to_scard_query(key), do: ["SCARD", key]

  # Sorted Set

  def to_zadd_query(key, score, value), do: ["ZADD", key, score, value]
  def to_zrem_query(key, value), do: ["ZREM", key, value]

  def to_zrank_query(key, value, opts \\ []) do
    create_query(opts, ["ZRANK", key, value])
  end

  def to_zrevrank_query(key, value, opts \\ []) do
    create_query(opts, ["ZREVRANK", key, value])
  end

  def to_zrange_query(key, s_pos, e_pos, opts \\ []) do
    create_query(opts, ["ZRANGE", key, s_pos, e_pos])
  end

  def to_zremrangebyscore_query(key, min, max), do: ["ZREMRANGEBYSCORE", key, min, max]
  def to_zremrangebyrank_query(key, s_pos, e_pos), do: ["ZREMRANGEBYRANK", key, s_pos, e_pos]

  def to_zscore_query(key, value), do: ["ZSCORE", key, value]
  def to_zincrby_query(key, score, value), do: ["ZINCRBY", key, score, value]
  def to_zcount_query(key, min, max), do: ["ZCOUNT", key, min, max]

  def limit(command, offset \\ 0, count),
    do: if(is_integer(count), do: command ++ ["LIMIT", offset, count], else: command)

  # Common

  @options ~w(NX XX GT LT)a
  def to_del_query(keys) when is_list(keys) do
    ["DEL"] ++ keys
  end

  def to_del_query(key), do: ["DEL", key]

  def to_expire_query(key, seconds, opts \\ []) do
    Recto.Query.check_options!(opts, @options, "Common.to_expire_query/3")
    create_query(opts, ["EXPIRE", key, seconds])
  end

  def to_exists_query(keys) when is_list(keys) do
    ["EXISTS"] ++ keys
  end

  def to_exists_query(key) do
    ["EXISTS", key]
  end

  defp create_query([{key, value} | t], query) when value do
    create_query(t, query ++ [key])
  end

  defp create_query([], query), do: query

  defp create_query([{:EX, seconds} | t], query) when is_integer(seconds) do
    create_query(t, query ++ ["EX", seconds])
  end

  defp create_query([{:EX, seconds} | t], query) when not is_integer(seconds) do
    create_query(t, query)
  end

  defp create_query([{key, value} | t], query) when value do
    create_query(t, query ++ [key])
  end

  defp create_query([{_key, value} | t], query) when not value do
    create_query(t, query)
  end

  def check_options!(opts, valid, fun_arity) do
    case Enum.find(opts, fn {k, _} -> k not in valid end) do
      {k, _} -> raise ArgumentError, "invalid option #{inspect(k)} for #{fun_arity}"
      nil -> :ok
    end
  end
end
