defmodule Tortoise311.Transport.WssConnectionTest do
  use ExUnit.Case
  import Mock
  alias Tortoise311.Transport.WssConnection

  describe "start_link/1" do
    test "without session_id returns error" do
      assert {:error, :missing_options} = WssConnection.start_link(%{url: "wss://example.com"})
    end

    test "without url returns error" do
      assert {:error, :missing_options} = WssConnection.start_link(%{session_id: "session_id"})
    end

    test "with bad url fails" do
      {:error, _} =
        WssConnection.start_link(%{session_id: "session_id", url: "wss://example.com"})
    end

    test "with good info starts the server (mock)" do
      with_mock WebSockex,
        start_link: fn url, module, _opts, _more_opts ->
          assert url == "wss://example.com"
          assert module == Tortoise311.Transport.WssConnection
          {:ok, 0}
        end do
        assert {:ok, 0} =
                 WssConnection.start_link(%{session_id: "session_id", url: "wss://example.com"})
      end
    end

    test "with good info starts the server" do
      session_id = "session_id"
      url = "wss://ws.postman-echo.com/raw"
      {:ok, pid} = WssConnection.start_link(%{session_id: session_id, url: url})
      assert is_pid(pid)
      GenServer.stop(pid)
    end
  end

  #  describe "recv/2" do
  #    setup do
  #      session_id = "session_id"
  #      url = "wss://ws.postman-echo.com/raw"
  #      pid = start_supervised!({WssConnection, %{session_id: session_id, url: url}})
  #      on_exit(fn -> stop_supervised(pid) end)
  #      {:ok, pid}
  #    end
  #
  #    test "returns :timeout when no message", context do
  #      assert {:timeout} = WssConnection.recv(context.pid, 1)
  #    end
  #  end
end
