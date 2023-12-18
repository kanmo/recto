#defmodule Recto.TestAdapter do
#  def init(opts) do
#    dbg()
#    {:ok, Supervisor.child_spec({Redix, host: "localhost", port: 6379, name: :rectoredix}, [])}
#  end
#end

defmodule Recto.TestRepo do
  use Recto.Repo, otp_app: :recto, adapter: Redix
  require Logger

  def init(_type, opts) do
    dbg()
    {:ok, opts}
  end
end

Recto.TestRepo.start_link()