defmodule Track.Exchanges.Bitmex.APIImplTest do
  use Track.DataCase, async: true

  import Track.AccountsFixtures
  import Track.ExchangesFixtures

  alias Track.Exchanges.Bitmex.APIImpl

  setup do
    scope = user_scope_fixture()
    bitmex_setting = bitmex_setting_fixture(scope)
    bypass = Bypass.open()

    # Configure the application to use the bypass URL for this test
    base_url = "http://localhost:#{bypass.port}"
    Application.put_env(:track, :bitmex_api_base_url, base_url)

    # clean up application env after test
    on_exit(fn -> Application.delete_env(:track, :bitmex_api_base_url) end)

    {:ok, bypass: bypass, scope: scope, bitmex_setting: bitmex_setting}
  end

  test "get_balance/2 makes a correct request and handles the response", %{
    bypass: bypass,
    scope: scope,
    bitmex_setting: bitmex_setting
  } do
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

    expect_api_call(bypass, path, query, bitmex_setting, expected_response_body)

    assert {:ok,
            [
              %{
                "account" => 1234,
                "currency" => "XBt",
                "walletBalance" => 5678
              }
            ]} == APIImpl.get_balance(scope, currency)
  end

  test "get_instrument/2 makes a correct request and handles the response", %{
    bypass: bypass,
    scope: scope,
    bitmex_setting: bitmex_setting
  } do
    symbol = "XBTUSD"
    path = "/api/v1/instrument"
    query = "symbol=#{symbol}"

    expected_response_body = """
    [
      {
        "lastPrice": 1234
      }
    ]
    """

    expect_api_call(bypass, path, query, bitmex_setting, expected_response_body)

    assert {:ok,
            [
              %{
                "lastPrice" => 1234
              }
            ]} == APIImpl.get_instrument(scope, symbol)
  end

  test "get_positions/2 makes a correct request and handles the response", %{
    bypass: bypass,
    scope: scope,
    bitmex_setting: bitmex_setting
  } do
    symbol = "XBTUSD"
    path = "/api/v1/position"
    query = "symbol=#{symbol}"

    expected_response_body = """
    [
      {
        "currentQty": 100,
        "isOpen": true,
        "leverage": 5,
        "realisedPnl": 456,
        "unrealisedPnl": 123
      }
    ]
    """

    expect_api_call(bypass, path, query, bitmex_setting, expected_response_body)

    assert {:ok,
            [
              %{
                "currentQty" => 100,
                "isOpen" => true,
                "leverage" => 5,
                "realisedPnl" => 456,
                "unrealisedPnl" => 123
              }
            ]} == APIImpl.get_positions(scope, symbol)
  end

  defp expect_api_call(bypass, path, query, bitmex_setting, expected_response_body) do
    Bypass.expect_once(bypass, "GET", path, fn conn ->
      assert conn.query_string == query
      assert_auth_headers(conn, bitmex_setting.api_key)
      Plug.Conn.resp(conn, 200, expected_response_body)
    end)
  end

  defp assert_auth_headers(conn, api_key) do
    assert Plug.Conn.get_req_header(conn, "api-key") == [api_key]
    assert Plug.Conn.get_req_header(conn, "api-expires") != []
    assert Plug.Conn.get_req_header(conn, "api-signature") != []
  end
end
