defmodule Recto.Repo.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(repo, otp_app, adapter, opts) do
    name = Keyword.get(opts, :name, repo)
    sup_opts = if name, do: [name: name], else: []

    Supervisor.start_link(__MODULE__, {name, repo, otp_app, adapter, opts}, sup_opts)
  end

  def runtime_config(type, repo, otp_app, _opts) do
    config = Application.get_env(otp_app, repo, [])

    case repo_init(type, repo, config) do
      {:ok, config} ->
        {_url, config} = Keyword.pop(config, :host)
        # TODO: parse_url
        #            {:ok, Keyword.merge(config, parse_url(url || ""))}
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
