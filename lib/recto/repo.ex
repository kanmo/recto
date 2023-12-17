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

      def config do
        {:ok, config} = Recto.Repo.Supervisor.runtime_config(:runtime, __MODULE__, @otp_app, [])
        config
      end

      def __adapter__ do
        @adapter
      end

      def child_spec(opts) do
        dbg()
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        dbg()
        Recto.Repo.Supervisor.start_link(__MODULE__, @otp_app, @adapter, opts)
      end

    end
  end
end