defmodule Tortoise311.Transport.WSS do
  @moduledoc false

  @behaviour Tortoise311.Transport

  alias Tortoise311.Transport

  @default_opts [verify: :verify_peer]

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
  def connect(_host, _port, _opts, _timeout) do
    # TODO: this needs to be the pid of the wss connection
    {:ok, nil}
  end

  @impl Tortoise311.Transport
  def recv(socket, length, timeout) do
    :ssl.recv(socket, length, timeout)
  end

  @impl Tortoise311.Transport
  def send(socket, data) do
    :ssl.send(socket, data)
  end

  @impl Tortoise311.Transport
  def setopts(socket, opts) do
    :ssl.setopts(socket, opts)
  end

  @impl Tortoise311.Transport
  def getstat(socket) do
    :ssl.getstat(socket)
  end

  @impl Tortoise311.Transport
  def getstat(socket, opt_names) do
    :ssl.getstat(socket, opt_names)
  end

  @impl Tortoise311.Transport
  def controlling_process(socket, pid) do
    :ssl.controlling_process(socket, pid)
  end
end
