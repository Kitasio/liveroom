defmodule Track.Exchanges.BitmexClient.APIImplTest do
  use Track.DataCase, async: true

  import Track.AccountsFixtures
  import Track.ExchangesFixtures

  alias Track.Exchanges.BitmexClient.APIImpl

  setup do
    bypass = Bypass.open()
    # clean up application env after test
    on_exit(fn -> Application.delete_env(:track, :bitmex_api_base_url) end)
    {:ok, bypass: bypass}
  end

  test "get_balance/2 makes a correct request and handles the response", %{bypass: bypass} do
    scope = user_scope_fixture()
    bitmex_setting = bitmex_setting_fixture(scope)

    # Configure the application to use the bypass URL for this test
    base_url = "http://localhost:#{bypass.port}"
    Application.put_env(:track, :bitmex_api_base_url, base_url)

    currency = "XBt"
    path = "/api/v1/user/margin"
    query = "currency=#{currency}"

    expected_response_body = """
    [
      {
        "account": 1234,
        "currency": "XBt",
        "walletBalance": 5678
      }
    ]
    """

    Bypass.expect_once(bypass, "GET", path, fn conn ->
      assert conn.query_string == query

      api_key_header = Plug.Conn.get_req_header(conn, "api-key")
      assert api_key_header == [bitmex_setting.api_key]

      api_expires_header = Plug.Conn.get_req_header(conn, "api-expires")
      assert api_expires_header != []

      api_signature_header = Plug.Conn.get_req_header(conn, "api-signature")
      assert api_signature_header != []

      Plug.Conn.resp(conn, 200, expected_response_body)
    end)

    assert {:ok,
            [
              %{
                "account" => 1234,
                "currency" => "XBt",
                "walletBalance" => 5678
              }
            ]} == APIImpl.get_balance(scope, currency)
  end
end
