defmodule Track.Exchanges.Bitmex.MarketDataTest do
  alias Track.Exchanges.MarketDataAPI.Instrument
  use Track.DataCase
  use ExUnit.Case, async: true

  import Mox
  import Track.AccountsFixtures, only: [user_scope_fixture: 0]

  setup :verify_on_exit!

  @symbol "XBTUSD"
  @valid_get_instrument_api_response {:ok,
                                      [
                                        %{
                                          "lastPrice" => 90999,
                                          "quoteCurrency" => "USD",
                                          "symbol" => @symbol
                                        }
                                      ]}

  test "gets instrument" do
    Track.Exchanges.Bitmex.MockAPI
    |> expect(:get_instrument, fn _scope, _symbol -> @valid_get_instrument_api_response end)

    valid_result = %Instrument{symbol: @symbol, currency: "USD", last_price: "90999"}

    assert Track.Exchanges.Bitmex.MarketData.get_instrument(user_scope_fixture(), @symbol) ==
             valid_result
  end
end
