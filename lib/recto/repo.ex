defmodule Recto.Repo do
  @moduledoc false

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Recto.Repo

      otp_app = Keyword.fetch!(opts, :otp_app)
      adapter = opts[:adapter]

      unless adapter do
        raise ArgumentError, "missing :adapter option"
      end

      if Code.ensure_compiled(adapter) != {:module, adapter} do
        raise ArgumentError, "adapter #{inspect adapter} was not compiled, " <>
                             "ensure it is correct and it is included as a project dependency"
      end

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

      def set(key, schema, opts \\ []) do
        repo = @default_dynamic_repo
        %{adapter: adapter} = Recto.Repo.Registry.lookup(repo)

        data = :erlang.term_to_binary(schema)
        adapter.command(:rectoredix, ["SET", key, data])
      end

      def get(schema, key, opts \\ []) do
        repo = @default_dynamic_repo

        %{adapter: adapter} = Recto.Repo.Registry.lookup(repo)
        case adapter.command(:rectoredix, ["GET", key]) do
          {:ok, binary} ->
            {:ok, :erlang.binary_to_term(binary)}

          other ->
            other
        end
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
  @callback command(connection :: GenServer.server(), command :: [String.Chars.t()], opts :: Keyword.t()) ::
              {:ok, any()}
              | {:error, atom()}
end