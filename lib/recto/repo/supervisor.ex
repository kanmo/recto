defmodule Recto.Repo.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(repo, otp_app, adapter, opts) do
    name= Keyword.get(opts, :name, repo)
    sup_opts = if name, do: [name: name], else: []
    Supervisor.start_link(__MODULE__, {name, repo, otp_app, adapter, opts}, sup_opts)
  end
end
