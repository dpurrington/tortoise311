defmodule Tortoise311.Transport.WssConnection do
  use GenServer
  require Logger

  alias Tortoise311.Transport.WssGateway

  @moduledoc false

  # size limit on buffer to prevent memory exhaustion
  # older messages fall off
  @max_buffer_size 10

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    case WssGateway.start_link(opts ++ [{:receiver, self()}]) do
      {:ok, pid} ->
        {:ok, %{buffer: :queue.new(), gateway: pid, controller: nil}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # API
  def send(server, message) do
    GenServer.cast(server, {:send, message})
  end

  def set_controller(_server, nil), do: raise("nil controller not allowed")

  def set_controller(server, pid) do
    GenServer.call(server, {:set_controller, pid})
  end

  def recv(server, timeout) do
    quit_time = DateTime.add(DateTime.utc_now(), timeout)
    do_recv(server, quit_time)
  end

  defp do_recv(server, quit_time) do
    if DateTime.diff(quit_time, DateTime.utc_now()) > 0 do
      # check for a message on the server
      # note that we don't sleep on the server b/c
      # it would halt server processing
      case GenServer.call(server, :recv) do
        {:ok, message} ->
          {:ok, message}

        :empty ->
          # server does not have any messages, sleep and try again
          :timer.sleep(500)
          do_recv(server, quit_time)
      end
    else
      :timeout
    end
  end

  # GenServer callbacks
  @impl true
  def handle_call(:recv, _from, %{buffer: buffer} = st) do
    case :queue.out(buffer) do
      {{:value, frame}, buffer} ->
        Logger.debug("Removed item from buffer: #{inspect(frame)}")
        {:reply, {:ok, frame}, %{st | buffer: buffer}}

      {:empty, _} ->
        {:reply, :empty, st}
    end
  end

  @impl true
  def handle_call({:set_controller, pid}, _from, %{buffer: buffer} = st) do
    empty_buffer(buffer, pid)

    {:reply, :ok, %{st | controller: pid}}
  end

  @impl true
  def handle_info({:message, {type, msg} = frame}, %{buffer: buffer, controller: controller} = st) do
    Logger.debug("received message - type: #{inspect(type)} -- message: #{inspect(msg)}")

    case controller do
      nil ->
        {:noreply, %{st | buffer: add_to_buffer(buffer, frame)}}

      pid ->
        Process.send(pid, {:message, frame}, [])
        {:noreply, st}
    end
  end

  @impl true
  def handle_cast({:send, frame}, %{gateway: gateway} = st) do
    WssGateway.send(gateway, frame)
    {:noreply, st}
  end

  defp empty_buffer(buffer, controller) do
    Task.start_link(fn ->
      :queue.to_list(buffer)
      |> Enum.each(fn message -> Process.send(controller, {:message, message}, []) end)
    end)
  end

  defp add_to_buffer(buffer, item, max_size \\ @max_buffer_size) do
    if :queue.len(buffer) >= max_size do
      Logger.debug("Buffer full, dropping oldest message")
      buffer = :queue.drop(buffer)
      :queue.in(item, buffer)
    else
      :queue.in(item, buffer)
    end
  end
end
