defmodule Tortoise311.Transport.Wss.GatewaySupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Supervisor.init(
      [
        {Tortoise311.Transport.Wss.Gateway, opts}
      ],
      strategy: :one_for_one
    )

    {:ok, opts}
  end
end
