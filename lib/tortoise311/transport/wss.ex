defmodule Tortoise311.Transport.WSS do
  @moduledoc false

  @behaviour Tortoise311.Transport

  import Kernel, except: [send: 2]

  alias Tortoise311.Transport
  alias Tortoise311.Transport.Wss.Connection

  @default_opts []

  @impl Tortoise311.Transport
  def new(opts) do
    {host, opts} = Keyword.pop(opts, :host)
    {port, opts} = Keyword.pop(opts, :port)
    {list_opts, opts} = Keyword.pop(opts, :opts, [])
    host = coerce_host(host)
    opts = Keyword.merge(@default_opts, opts)
    opts = [:binary, {:packet, :raw}, {:active, false} | opts] ++ list_opts
    %Transport{type: __MODULE__, host: host, port: port, opts: opts}
  end

  defp coerce_host(host) when is_binary(host) do
    String.to_charlist(host)
  end

  defp coerce_host(otherwise) do
    otherwise
  end

  @impl Tortoise311.Transport
  def connect(host, port, opts, _timeout) do
    url = "wss://#{host}:#{port}#{opts[:path]}}"
    socket = Connection.start_link(url: url)
    {:ok, socket}
  end

  @impl Tortoise311.Transport
  def recv(socket, _length, timeout) do
    Connection.recv(socket, timeout)
  end

  @impl Tortoise311.Transport
  def send(socket, data) do
    Connection.send(socket, data)
  end

  @impl Tortoise311.Transport
  def setopts(_socket, _opts) do
    # this is a no-op for wss
    # because we are not pulling off one message at a time
    :ok
  end

  @impl Tortoise311.Transport
  def getstat(_socket) do
    {:ok, :not_implemented}
  end

  @impl Tortoise311.Transport
  def getstat(_socket, _opt_names) do
    {:ok, :not_implemented}
  end

  @impl Tortoise311.Transport
  def controlling_process(socket, pid) do
    Connection.set_controller(socket, pid)
  end
end
