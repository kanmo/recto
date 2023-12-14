defmodule Recto.TestAdapter do
  def init(opts) do
    {:ok, Supervisor.child_spec({Redix, host: "localhost", port: 6379, name: :rectoredix}, [strategy: :one_for_one])}
  end
end

defmodule Recto.TestRepo do
  use Recto.Repo, otp_app: :recto, adapter: Recto.TestAdapter

  def init() do
  end
end

Recto.TestRepo.start_link()