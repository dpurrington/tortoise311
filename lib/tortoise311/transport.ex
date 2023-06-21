defmodule Tortoise311.Transport do
  @moduledoc """
  Abstraction for working with network connections; this is done to
  normalize the `:ssl`, `:gen_tcp`, and `wss` modules, so they get a similar
  interface.

  This work has been heavily inspired by the Ranch project by
  NineNines.
  """

  @opaque t :: %__MODULE__{
            type: atom(),
            host: binary(),
            port: non_neg_integer(),
            opts: [term()]
          }

  @enforce_keys [:type, :host, :port]
  defstruct type: nil, host: nil, port: nil, opts: []

  @doc """
  Create a new Transport specification used by the Connection process
  to log on to the MQTT server. This allow us to filter the options
  passed to the connection type, and guide the user to connect to the
  individual transport type.
  """
  @spec new({atom(), [term()]}) :: t()
  def new({transport, opts}) do
    %Tortoise311.Transport{type: ^transport} = transport.new(opts)
  end

  @type socket() :: any()
  @type opts() :: any()
  @type stats() :: any()

  @callback new(opts()) :: Tortoise311.Transport.t()

  @callback connect(charlist(), :inet.port_number(), opts(), timeout()) ::
              {:ok, socket()} | {:error, atom()}

  @callback recv(socket(), non_neg_integer(), timeout()) ::
              {:ok, any()} | {:error, :closed | :timeout | atom()}

  @callback send(socket(), iodata()) :: :ok | {:error, atom()}

  @callback setopts(socket(), opts()) :: :ok | {:error, atom()}

  @callback getstat(socket()) :: {:ok, stats()} | {:error, atom()}

  @callback getstat(socket(), [atom()]) :: {:ok, stats()} | {:error, atom()}

  @callback controlling_process(socket(), pid()) :: :ok | {:error, :closed | :now_owner | atom()}
end
