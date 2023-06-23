defmodule Tortoise311.Transport.Wss.Gateway do
  use WebSockex

  require Logger

  @moduledoc false

  def start_link(opts) do
    WebSockex.start_link(opts[:url], __MODULE__, %{receiver: opts[:receiver]}, opts)
  end

  def send(client, message) do
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_frame({type, msg} = frame, st) do
    Logger.debug("Received message - type: #{inspect(type)} -- message: #{inspect(msg)}")

    pid = st[:receiver]
    Logger.debug("sending to #{inspect(pid)}")

    Kernel.send(pid, {:message, frame})

    {:ok, st}
  end
end
