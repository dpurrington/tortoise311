defmodule Tortoise311.Transport.WssConnectionTest do
  use ExUnit.Case
  import Mock
  require Logger
  alias Tortoise311.Transport.WssConnection
  alias Tortoise311.Transport.WssGateway

  describe "start_link/1" do
    test "without session_id returns error" do
      assert {:error, _} = WssConnection.start_link(url: "wss://example.com")
    end

    test "without url returns error" do
      assert {:error, _} = WssConnection.start_link(session_id: "session_id")
    end

    test "with bad url fails" do
      {:error, _} = WssConnection.start_link(session_id: "session_id", url: "wss://example.com")
    end

    test "with good info starts the server (mock)" do
      session_id = "session_id"

      with_mock WssGateway,
        start_link: fn opts ->
          assert opts[:url] == "wss://example.com"

          assert opts[:headers] == [
                   {<<"X-Requested-With">>, "com.sengled.life2"},
                   {<<"Cookie">>, "JSESSIONID=#{session_id}"},
                   {<<"sid">>, session_id}
                 ]

          {:ok, 0}
        end do
        headers = [
          {<<"X-Requested-With">>, "com.sengled.life2"},
          {<<"Cookie">>, "JSESSIONID=#{session_id}"},
          {<<"sid">>, session_id}
        ]

        WssConnection.start_link(
          headers: headers,
          session_id: session_id,
          url: "wss://example.com"
        )
      end
    end

    test "with good info starts the server" do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = WssConnection.start_link(session_id: session_id, url: url)
      assert is_pid(pid)
      GenServer.stop(pid)
    end
  end

  describe "recv/2" do
    setup do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = WssConnection.start_link(session_id: session_id, url: url)
      {:ok, pid: pid}
    end

    test "returns :timeout when no message", context do
      assert :timeout = WssConnection.recv(context.pid, 1)
    end

    test "returns response", context do
      WssConnection.send(context.pid, "ping")
      assert {:ok, {:text, "ping"}} = WssConnection.recv(context.pid, 5)
    end

    test "keeps only the max-latest messages, returns them in sent order", context do
      WssConnection.send(context.pid, "ping0")
      WssConnection.send(context.pid, "ping1")
      WssConnection.send(context.pid, "ping2")
      WssConnection.send(context.pid, "ping3")
      WssConnection.send(context.pid, "ping4")
      WssConnection.send(context.pid, "ping5")
      WssConnection.send(context.pid, "ping6")
      WssConnection.send(context.pid, "ping7")
      WssConnection.send(context.pid, "ping8")
      WssConnection.send(context.pid, "ping9")
      WssConnection.send(context.pid, "ping10")
      assert {:ok, {:text, "ping1"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping2"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping3"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping4"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping5"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping6"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping7"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping8"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping9"}} = WssConnection.recv(context.pid, 5)
      assert {:ok, {:text, "ping10"}} = WssConnection.recv(context.pid, 5)
    end
  end

  describe "set_controller/2" do
    setup do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = WssConnection.start_link(session_id: session_id, url: url)
      {:ok, pid: pid}
    end

    test "returns :ok", context do
      assert :ok = WssConnection.set_controller(context.pid, self())
    end

    test "raises when nil", context do
      assert_raise RuntimeError, fn ->
        WssConnection.set_controller(context.pid, nil)
      end
    end

    test "sends message after call", context do
      :ok = WssConnection.set_controller(context.pid, self())
      WssConnection.send(context.pid, "ping")
      assert_receive {:message, {:text, "ping"}}
    end

    test "sends buffered message after call", context do
      :ok = WssConnection.send(context.pid, "ping")
      :ok = WssConnection.set_controller(context.pid, self())
      assert_receive {:message, {:text, "ping"}}
    end

    test "stops buffering", context do
      :ok = WssConnection.send(context.pid, "ping")
      :ok = WssConnection.set_controller(context.pid, self())
      :timeout = WssConnection.recv(context.pid, 1)
      assert_receive {:message, {:text, "ping"}}
    end
  end
end
