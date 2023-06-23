defmodule Tortoise311.Transport.Wss.ConnectionTest do
  use ExUnit.Case
  import Mock
  require Logger
  alias Tortoise311.Transport.Wss.Connection
  alias Tortoise311.Transport.Wss.Gateway

  describe "start_link/1" do
    test "without session_id returns error" do
      assert {:error, _} = Connection.start_link(url: "wss://example.com")
    end

    test "without url returns error" do
      assert {:error, _} = Connection.start_link(session_id: "session_id")
    end

    test "with bad url fails" do
      {:error, _} = Connection.start_link(session_id: "session_id", url: "wss://example.com")
    end

    test "with good info starts the server (mock)" do
      session_id = "session_id"

      with_mock Gateway,
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

        Connection.start_link(
          headers: headers,
          session_id: session_id,
          url: "wss://example.com"
        )
      end
    end

    test "with good info starts the server" do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = Connection.start_link(session_id: session_id, url: url)
      assert is_pid(pid)
      GenServer.stop(pid)
    end
  end

  describe "recv/2" do
    setup do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = Connection.start_link(session_id: session_id, url: url)
      {:ok, pid: pid}
    end

    test "returns :timeout when no message", context do
      assert :timeout = Connection.recv(context.pid, 1)
    end

    test "returns response", context do
      Connection.send(context.pid, "ping")
      assert {:ok, {:text, "ping"}} = Connection.recv(context.pid, 5)
    end

    test "keeps only the max-latest messages, returns them in sent order", context do
      Connection.send(context.pid, "ping0")
      Connection.send(context.pid, "ping1")
      Connection.send(context.pid, "ping2")
      Connection.send(context.pid, "ping3")
      Connection.send(context.pid, "ping4")
      Connection.send(context.pid, "ping5")
      Connection.send(context.pid, "ping6")
      Connection.send(context.pid, "ping7")
      Connection.send(context.pid, "ping8")
      Connection.send(context.pid, "ping9")
      Connection.send(context.pid, "ping10")
      assert {:ok, {:text, "ping1"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping2"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping3"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping4"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping5"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping6"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping7"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping8"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping9"}} = Connection.recv(context.pid, 5)
      assert {:ok, {:text, "ping10"}} = Connection.recv(context.pid, 5)
    end
  end

  describe "set_controller/2" do
    setup do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = Connection.start_link(session_id: session_id, url: url)
      {:ok, pid: pid}
    end

    test "returns :ok", context do
      assert :ok = Connection.set_controller(context.pid, self())
    end

    test "raises when nil", context do
      assert_raise RuntimeError, fn ->
        Connection.set_controller(context.pid, nil)
      end
    end

    test "sends message after call", context do
      :ok = Connection.set_controller(context.pid, self())
      Connection.send(context.pid, "ping")
      assert_receive {:message, {:text, "ping"}}
    end

    test "sends buffered message after call", context do
      :ok = Connection.send(context.pid, "ping")
      :ok = Connection.set_controller(context.pid, self())
      assert_receive {:message, {:text, "ping"}}
    end

    test "stops buffering", context do
      :ok = Connection.send(context.pid, "ping")
      :ok = Connection.set_controller(context.pid, self())
      :timeout = Connection.recv(context.pid, 1)
      assert_receive {:message, {:text, "ping"}}
    end
  end
end
