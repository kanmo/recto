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
        # retrieve the runtime configuration
        config = Application.get_env(otp_app, __MODULE__, []) |> Keyword.merge([otp_app: otp_app])
        case repo_init(type, repo, config) do
          {:ok, config} ->
            {url, config} = Keyword.pop(config, :url)
            # TODO: parse_url
#            {:ok, Keyword.merge(config, parse_url(url || ""))}
            config
          :ignore ->
            raise ArgumentError, "configuration setting is invalid"
        end
      end

      def repo_init(type, repo, config) do
        if Code.ensure_loaded?(repo) and function_exported?(repo, :init, 2) do
          repo.init(type, config)
        else
          {:ok, config}
        end
      end
    end
end
