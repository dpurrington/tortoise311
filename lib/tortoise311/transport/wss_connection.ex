defmodule Tortoise311.Transport.WssConnection do
  use WebSockex

  require Logger

  @moduledoc false

  # size limit on buffer to prevent memory exhaustion
  # older messages fall off
  @max_buffer_size 10

  def start_link(%{session_id: session_id, url: url} = opts) do
    headers = [
      {<<"X-Requested-With">>, "com.sengled.life2"},
      {<<"Cookie">>, "JSESSIONID=#{session_id}"},
      {<<"sid">>, session_id}
    ]

    temp_buffer = Agent.start_link(fn -> :queue.new() end)
    opts = Map.put(opts, :temp_buffer, temp_buffer)

    WebSockex.start_link(url, __MODULE__, opts, extra_headers: headers)
  end

  def start_link(_opts), do: {:error, :missing_options}

  # API
  def send(client, message) do
    WebSockex.send_frame(client, {:text, message})
  end

  def set_controller(connection, pid) do
    GenServer.cast(connection, {:set_controller, pid})
  end

  def recv(connection, timeout) do
    do_recv(connection, DateTime.add(DateTime.utc_now(), timeout))
  end

  defp do_recv(connection, quit_time) do
    if DateTime.utc_now() > quit_time do
      {:timeout}
    end

    case get_buffered_message(connection.temp_buffer) do
      {:ok, message} ->
        {:ok, message}

      {:empty} ->
        :timer.sleep(500)
        do_recv(connection, quit_time)
    end
  end

  defp get_buffered_message(temp_buffer) do
    Agent.get_and_update(temp_buffer, &:queue.out(&1))
  end

  def handle_cast({:set_controller, pid}, _from, %{temp_buffer: temp_buffer} = st) do
    process_and_shutdown_buffer(temp_buffer, pid)

    new_st =
      st
      |> Map.put(:controller, pid)
      |> Map.put(:temp_buffer, nil)

    {:reply, :ok, new_st}
  end

  def handle_info(message, state) do
    Logger.warn("Unknown info message: #{message}")
    {:ok, state}
  end

  defp process_and_shutdown_buffer(temp_buffer, pid) do
    buffer_data = Agent.get(temp_buffer, fn content -> content end)
    Agent.stop(temp_buffer)

    Task.start_link(fn ->
      buffer_data
      |> :queue.to_list()
      |> Enum.each(fn message -> Process.send(pid, {:message, message}, []) end)
    end)
  end

  def handle_frame({type, msg} = frame, st) do
    IO.inspect("Received message - type: #{inspect(type)} -- message: #{inspect(msg)}")

    case Map.get(st, :controller) do
      # TODO: need to limit the size of the buffer so we don't run out of memory
      nil -> Agent.update(st.temp_buffer, &add_to_buffer(&1, frame))
      pid -> Process.send(pid, {:message, frame}, [])
    end

    {:ok, st}
  end

  def add_to_buffer(queue, item, max_size \\ @max_buffer_size) do
    if :queue.len(queue) == max_size do
      ^queue = :queue.drop(queue)
    end

    :queue.in(item, queue)
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end
end
