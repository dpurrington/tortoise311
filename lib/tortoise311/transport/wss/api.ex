defmodule Tortoise311.Transport.Wss.Api do
  def get_session_id(username, password) do
    url = "https://ucenter.cloud.sengled.com/user/app/customer/v2/AuthenCross.json"

    headers = %{
      "Content-Type": "application/json",
      Host: "element.cloud.sengled.com:443",
      Connection: "keep-alive"
    }

    device_id = "foo"

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

  def get_wss_headers(session_id) do
    [
      {<<"X-Requested-With">>, "com.sengled.life2"},
      {<<"Cookie">>, "JSESSIONID=#{session_id}"},
      {<<"sid">>, session_id}
    ]
  end

  def get_url() do
    "wss://element.cloud.sengled.com/mqtt"
  end

  def get_opts() do
    username = System.get_env("SENGLED_USERNAME")
    password = System.get_env("SENGLED_PASSWORD")
    sid = get_session_id(username, password)
    headers = get_wss_headers(sid)
    [url: get_url(), headers: headers]
  end
end
