defmodule Recto.TestAdapter do
  @behaviour Recto.Adapter
  def command(conn, command, opts \\ []) do
    Redix.command(conn, command, opts)
  end

  def init(opts) do
    {:ok, Redix.child_spec(opts)}
  end
end


# expect below settings in config.exs
# config :recto, Recto.TestRepo,
#   host: "localhost",
#   port: 6379
Application.put_env(:recto, Recto.TestRepo, [host: "localhost", port: 6379])

defmodule Recto.TestRepo do
  use Recto.Repo, otp_app: :recto, adapter: Recto.TestAdapter
  require Logger

  def init(_type, opts) do
    {:ok, opts}
  end
end

Recto.TestRepo.start_link()