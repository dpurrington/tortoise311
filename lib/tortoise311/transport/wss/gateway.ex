defmodule Tortoise311.Transport.Wss.Gateway do
  use WebSockex

  require Logger

  @moduledoc false

  def start_link(opts) do
    {receiver, opts} = Keyword.pop(opts, :receiver)
    {headers, opts} = Keyword.pop(opts, :headers)
    {url, _opts} = Keyword.pop(opts, :url)

    WebSockex.start_link(url, __MODULE__, %{receiver: receiver}, extra_headers: headers)
  end

  def send(client, message) do
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_disconnect(_conn_status, state) do
    {:reconnect, state}
  end

  def handle_frame({type, msg} = frame, st) do
    Logger.debug("Received message - type: #{inspect(type)} -- message: #{inspect(msg)}")

    pid = st[:receiver]
    Logger.debug("sending to #{inspect(pid)}")

    Kernel.send(pid, {:message, frame})

    {:ok, st}
  end
end
