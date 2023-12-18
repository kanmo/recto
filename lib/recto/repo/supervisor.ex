defmodule Recto.Repo.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(repo, otp_app, adapter, opts) do
    name= Keyword.get(opts, :name, repo)
    sup_opts = if name, do: [name: name], else: []

    Supervisor.start_link(__MODULE__, {name, repo, otp_app, adapter, opts}, sup_opts)
  end

  def runtime_config(type, repo, otp_app, opts) do
    config = Application.get_env(otp_app, __MODULE__, []) |> Keyword.merge([otp_app: otp_app])

    case repo_init(type, repo, config) do
      {:ok, config} ->
        {url, config} = Keyword.pop(config, :url)
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
    dbg()
    case runtime_config(:supervisor, repo, otp_app, opts) do
      {:ok, opts} ->
#        {:ok, child} = adapter.init(opts)
# TODO opts
        child = adapter.child_spec(name: :rectoredix)
        child_spec = wrap_child_spec(child, [name, adapter])
        Supervisor.init([child_spec], strategy: :one_for_one, max_restarts: 0)

      :ignore ->
        :ignore
    end
  end

  def start_child({mod, fun, args}, name, adapter) do

    case apply(mod, fun, args) do
      {:ok, pid} ->
        meta = %{pid: pid, adapter: adapter}
        s_pid = self()
        dbg()
        Recto.Repo.Registry.associate(s_pid, name, meta)
        {:ok, pid}

      other ->
        other
    end
  end

  defp wrap_child_spec({id, start, restart, shutdown, type, mods}, args) do
    {id,
      {__MODULE__, :start_child, [start | args]}, restart, shutdown, type, mods}
  end

  defp wrap_child_spec(%{start: start} = spec, args) do
    dbg()
    %{spec | start: {__MODULE__, :start_child, [start | args]}}
  end
end
