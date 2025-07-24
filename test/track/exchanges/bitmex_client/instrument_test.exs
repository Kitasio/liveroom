defmodule Track.Exchanges.BitmexClient.InstrumentTest do
  alias Track.Exchanges.BitmexClient.Instrument
  use Track.DataCase
  use ExUnit.Case, async: true

  import Mox
  import Track.AccountsFixtures, only: [user_scope_fixture: 0]

  setup :verify_on_exit!
  @symbol "XBTUSD"
  @valid_api_response {:ok, [%{"lastPrice" => 90999}]}
  @valid_get_instrument_response {:ok, [%Instrument{last_price: 90999}]}

  test "gets instrument successfully" do
    Track.Exchanges.BitmexClient.MockAPI
    |> expect(:get_instrument, fn _scope, _symbol -> @valid_api_response end)

    assert Track.Exchanges.BitmexClient.Instrument.get_instrument(user_scope_fixture(), @symbol) ==
             @valid_get_instrument_response
  end
end
