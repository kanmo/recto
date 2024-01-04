defmodule Recto.Repo do
  @moduledoc false

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Recto.Repo

      alias Recto.Query

      {otp_app, adapter} = Recto.Repo.Supervisor.compile_config(__MODULE__, opts)

      @otp_app otp_app
      @adapter adapter
      @default_dynamic_repo __MODULE__

      def config do
        {:ok, config} = Recto.Repo.Supervisor.runtime_config(:runtime, __MODULE__, @otp_app, [])
        config
      end

      def __adapter__ do
        @adapter
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        Recto.Repo.Supervisor.start_link(__MODULE__, @otp_app, @adapter, opts)
      end

      # stop supervisor

      #      @compile {:inline, get_dynamic_repo: 0}
      #
      #      def get_dynamic_repo() do
      #        dbg()
      #        Process.get({__MODULE__, :dynamic_repo}, @default_dynamic_repo)
      #      end
      #
      #      def put_dynamic_repo(dynamnic) when is_atom(dynamnic) or is_pid(dynamnic) do
      #        Process.put({__MODULE__, :dynamic_repo}, dynamnic) || @default_dynamic_repo
      #      end

      # Binary

      def set(key, schema, opts \\ []) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_set_query(key, data, opts)) do
          success = {:ok, "OK"} -> success
          other -> {:error, other}
        end
      end

      def get(key, opts \\ []) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_get_query(key)) do
          {:ok, nil} ->
            {:ok, nil}

          {:ok, binary} ->
            # TODO: check schema type
            {:ok, :erlang.binary_to_term(binary)}

          other ->
            {:error, other}
        end
      end

      # Common

      def expire(key, seconds, opts \\ []) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_expire_query(key, seconds, opts)) do
          {:ok, 1} -> :ok
          other -> {:error, other}
        end
      end

      def exists(keys) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_exists_query(keys)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def del(keys) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_del_query(keys)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      # List

      def rpush(key, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_rpush_query(key, data)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def lpop(key) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_lpop_query(key)) do
          success = {:ok, nil} ->
            success

          {:ok, value} ->
            {:ok, :erlang.binary_to_term(value)}

          other ->
            {:error, other}
        end
      end

      def lrange(key, start, stop) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_lrange_query(key, start, stop)) do
          success = {:ok, nil} ->
            success

          {:ok, values} ->
            {:ok, Enum.map(values, &:erlang.binary_to_term(&1))}

          other ->
            {:error, other}
        end
      end

      # Set

      def smembers(key) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_smembers_query(key)) do
          {:ok, values} ->
            {:ok, Enum.map(values, &:erlang.binary_to_term(&1))}

          other ->
            {:error, other}
        end
      end

      def sadd(key, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_sadd_query(key, data)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def srem(key, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_srem_query(key, data)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def sismember(key, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_sismember_query(key, data)) do
          {:ok, 0} -> {:ok, false}
          {:ok, 1} -> {:ok, true}
          other -> {:error, other}
        end
      end

      def scard(key) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_scard_query(key)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      # SortedSet

      def zadd(key, score, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_zadd_query(key, score, data)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def zrem(key, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_zrem_query(key, data)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def zrank(key, schema, opts \\ []) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_zrank_query(key, data, opts)) do
          {:ok, nil} -> {:ok, nil}
          # if specified WITHSCORE option, returns rank and score string
          {:ok, [rank, score]} -> {:ok, [rank, String.to_integer(score)]}
          {:ok, rank} -> {:ok, rank}
          other -> {:error, other}
        end
      end

      def zrevrank(key, schema, opts \\ []) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_zrevrank_query(key, data, opts)) do
          {:ok, nil} -> {:ok, nil}
          # if specified WITHSCORE option, returns rank and score string
          {:ok, [rank, score]} -> {:ok, [rank, String.to_integer(score)]}
          {:ok, rank} -> {:ok, rank}
          other -> {:error, other}
        end
      end

      def zrange(key, s_pos, e_pos, opts \\ []) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_zrange_query(key, s_pos, e_pos, opts)) do
          {:ok, values} ->
            case Keyword.get(opts, :withscores, false) do
              false ->
                {:ok, Enum.map(values, &:erlang.binary_to_term(&1))}

              true ->
                {:ok,
                 Enum.chunk_every(values, 2)
                 |> Enum.map(fn
                   [value, score] -> [:erlang.binary_to_term(value), String.to_integer(score)]
                 end)}
            end

          other ->
            {:error, other}
        end
      end

      def zremrangebyscore(key, min, max) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_zremrangebyscore_query(key, min, max)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def zremrangebyrank(key, s_pos, e_pos) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_zremrangebyrank_query(key, s_pos, e_pos)) do
          success = {:ok, num} -> success
          other -> {:error, other}
        end
      end

      def zscore(key, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_zscore_query(key, data)) do
          {:ok, nil} -> {:ok, nil}
          {:ok, score} -> {:ok, String.to_integer(score)}
          other -> {:error, other}
        end
      end

      def zincrby(key, score, schema) do
        adapter = find_adapter()
        data = :erlang.term_to_binary(schema)

        case adapter.command(adapter, Query.to_zincrby_query(key, score, data)) do
          {:ok, score} -> {:ok, String.to_integer(score)}
          other -> {:error, other}
        end
      end

      def zcount(key, min, max) do
        adapter = find_adapter()

        case adapter.command(adapter, Query.to_zcount_query(key, min, max)) do
          {:ok, num} -> {:ok, num}
          other -> {:error, other}
        end
      end

      defp find_adapter() do
        repo = @default_dynamic_repo
        %{adapter: adapter} = Recto.Repo.Registry.lookup(repo)
        adapter
      end
    end
  end

  @doc group: "User callbacks"
  @callback init(context :: :supervisor | :runtime, config :: Keyword.t()) ::
              {:ok, Keyword.t()} | :ignore

  @doc """
  Returns the adapter tied to the repository.
  """
  @doc group: "Runtime API"
  @callback __adapter__ :: Ecto.Adapter.t()

  @doc """
  Returns the adapter configuration stored in the `:otp_app` environment.

  If the `c:init/2` callback is implemented in the repository,
  it will be invoked with the first argument set to `:runtime`.
  """
  @doc group: "Runtime API"
  @callback config() :: Keyword.t()

  @doc """
  Starts any connection pooling or supervision and return `{:ok, pid}`
  or just `:ok` if nothing needs to be done.

  Returns `{:error, {:already_started, pid}}` if the repo is already
  started or `{:error, term}` in case anything else goes wrong.

  ## Options

  See the configuration in the moduledoc for options shared between adapters,
  """
  @doc group: "Runtime API"
  @callback start_link(opts :: Keyword.t()) ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}
end

defmodule Recto.Adapter do
  @doc """
  Initializes the adapter supervision tree by returning the children and adapter metadata.
  """
  @callback init(config :: Keyword.t()) :: {:ok, :supervisor.child_spec(), opts :: Keyword.t()}

  @callback command(
              connection :: GenServer.server(),
              command :: [String.Chars.t()],
              opts :: Keyword.t()
            ) ::
              {:ok, any()}
              | {:error, atom()}
end
