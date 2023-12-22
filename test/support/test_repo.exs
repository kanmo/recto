defmodule Recto.TestAdapter do
  @behaviour Recto.Adapter
  def command(conn, command, opts \\ []) do
    Redix.command(conn, command, opts)
  end

  def child_spec(opts) do
    Redix.child_spec(opts)
  end
end

defmodule Recto.TestRepo do
  use Recto.Repo, otp_app: :recto, adapter: Recto.TestAdapter
  require Logger

  def init(_type, opts) do
    {:ok, opts}
  end
end

Recto.TestRepo.start_link()