defmodule Tortoise311.Transport.WssConnection do
  use WebSockex
  require Logger

  @moduledoc false
  def start_link(opts) do
    session_id = get_session_id()
    url = Keyword.get(opts, :url)

    headers = [
      {<<"X-Requested-With">>, "com.sengled.life2"},
      {<<"Cookie">>, "JSESSIONID=#{session_id}"},
      {<<"sid">>, session_id}
    ]

    WebSockex.start_link(url, __MODULE__, opts, extra_headers: headers)
  end

  def get_session_id() do
    url = "https://ucenter.cloud.sengled.com/user/app/customer/v2/AuthenCross.json"

    headers = %{
      "Content-Type": "application/json",
      Host: "element.cloud.sengled.com:443",
      Connection: "keep-alive"
    }

    device_id = "foo"
    username = System.fetch_env!("SENGLED_USERNAME")
    password = System.fetch_env!("SENGLED_PASSWORD")

    payload = %{
      uuid: device_id,
      user: username,
      pwd: password,
      osType: "android",
      productCode: "life",
      appCode: "life"
    }

    {:ok, response} = HTTPoison.post(url, Poison.encode!(payload), headers)

    Poison.decode!(response.body)
    |> Map.get("jsessionId")
  end

  def handle_frame({type, msg}, st) do
    IO.inspect("Received message - type: #{inspect(type)} -- message: #{inspect(msg)}")
    {:ok, st}
  end
end
