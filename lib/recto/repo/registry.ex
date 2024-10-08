defmodule Recto.Repo.Registry do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def associate(pid, name, meta) do
    GenServer.call(__MODULE__, {:associate, pid, name, meta})
  end

  def lookup(repo) when is_atom(repo) do
      GenServer.whereis(repo)
      |> Kernel.||(raise "could not lookup Recto repo #{inspect repo} because it was not started or it does not exist")
      |> lookup()
  end

  def lookup(pid) when is_pid(pid) do
    :ets.lookup_element(__MODULE__, pid, 4)
  end


  # Callbacks

  @impl true
  def init(:ok) do
    table = :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    {:ok, table}
  end

  @impl true
  def handle_call({:associate, pid, name, value}, _from, table) do
    ref = Process.monitor(pid)
    true = :ets.insert(table, {pid, ref, name, value})
    {:reply, :ok, table}
  end

end
