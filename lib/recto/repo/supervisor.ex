defmodule Recto.Repo.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(repo, otp_app, adapter, opts) do
    name = Keyword.get(opts, :name, repo)
    sup_opts = if name, do: [name: name], else: []

    Supervisor.start_link(__MODULE__, {name, repo, otp_app, adapter, opts}, sup_opts)
  end

  def compile_config(_repo, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    adapter = opts[:adapter]

    unless adapter do
      raise ArgumentError, "missing :adapter option on use Recto.Repo"
    end

    if Code.ensure_compiled(adapter) != {:module, adapter} do
      raise ArgumentError, "adapter #{inspect adapter} not compiled, " <>
                           "ensure it is correct and it is included as a project dependency"

    end

    {otp_app, adapter}
  end

  def runtime_config(type, repo, otp_app, opts) do
    config = Application.get_env(otp_app, repo, [])
    config = config |> Keyword.merge(opts)

    case repo_init(type, repo, config) do
      {:ok, config} ->
        host = Keyword.fetch!(config, :host)
        unless is_binary(host) do
          raise ArgumentError, "configuration setting :host must be a string, got: #{inspect host}"
        end

        port = Keyword.fetch!(config, :port)
        unless is_integer(port) and port > 0 and port < 65536 do
          raise ArgumentError, "configuration setting :port must be an integer between 1 and 65535, got: #{inspect port}"
        end

        {:ok, config}

      :ignore ->
        raise ArgumentError, "configuration setting is invalid"
    end
  end

  defp repo_init(type, repo, config) do
    if Code.ensure_loaded?(repo) and function_exported?(repo, :init, 2) do
      repo.init(type, config)
    else
      {:ok, config}
    end
  end

  ## Callbacks

  @doc false
  def init({name, repo, otp_app, adapter, opts}) do
    case runtime_config(:supervisor, repo, otp_app, opts) do
      {:ok, opts} ->
        opts = Keyword.merge(opts, name: adapter)
        {:ok, adapter_spec} = adapter.init(opts)
        child_spec = wrap_child_spec(adapter_spec, [name, adapter])
        Supervisor.init([child_spec], strategy: :one_for_one, max_restarts: 0)

      :ignore ->
        :ignore
    end
  end

  def start_child({mod, fun, args}, name, adapter) do
    # start adapter
    case apply(mod, fun, args) do
      {:ok, adapter_pid} ->
        meta = %{pid: adapter_pid, adapter: adapter}
        Recto.Repo.Registry.associate(self(), name, meta)
        {:ok, adapter_pid}

      other ->
        other
    end
  end

  defp wrap_child_spec(%{start: start} = spec, args) do
    %{spec | start: {__MODULE__, :start_child, [start | args]}}
  end
end
