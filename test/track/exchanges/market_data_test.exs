defmodule Track.Exchanges.MarketDataTest do
  use Track.DataCase
  use ExUnit.Case, async: true
  import Mox
  import Track.AccountsFixtures
  alias Track.Exchanges.MarketDataAPI.Instrument

  setup :verify_on_exit!

  test "delegates get_instrument to the given module" do
    symbol = "XBTUSD"
    valid_response = %Instrument{symbol: symbol, currency: "USD", last_price: "109222"}

    Track.Exchanges.MockMarketDataAPI
    |> expect(:get_instrument, fn _scope, _symbol ->
      valid_response
    end)

    assert Track.Exchanges.MarketData.get_instrument(
             user_scope_fixture(),
             symbol,
             Track.Exchanges.MockMarketDataAPI
           ) == valid_response
  end

  test "raises if the last argument is not a module" do
    assert_raise FunctionClauseError, fn ->
      Track.Exchanges.MarketData.get_instrument(
        user_scope_fixture(),
        "XBTUSD",
        "binance"
      )
    end
  end
end
