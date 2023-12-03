defmodule Recto.Query do
  @moduledoc false

  defmodule List do
    def to_rpush(key, value), do: ["RPUSH", key, value]
    def to_lpop(key), do: ["LPOP", key]
    def to_lrange(key, start, stop), do: ["LRANGE", key, start, stop]
    def to_llen(key), do: ["LLEN", key]
    def to_ltrim(key, start, stop), do: ["LTRIM", key, start, stop]
  end

  defmodule Binary do
    def to_set(key, value, expiry_time) do
      case expiry_time do
        nil ->
          ["SET", key, value]

        seconds when is_integer(seconds) ->
          ["SET", key, value, "EX", expiry_time]
      end
    end
  end

  def to_del(key), do: ["DEL", key]
  def to_expire(key, seconds), do: ["EXPIRE", key, seconds]
  
end
