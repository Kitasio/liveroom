defmodule Track.Exchanges.BitmexClient.PositionTest do
  alias Track.Exchanges.BitmexClient.Position
  use Track.DataCase
  use ExUnit.Case, async: true

  import Mox
  import Track.AccountsFixtures, only: [user_scope_fixture: 0]

  setup :verify_on_exit!
  @symbol "XBTUSD"
  @valid_api_response {:ok,
                       [
                         %{
                           "isOpen" => false,
                           "realisedPnl" => 0,
                           "unrealisedPnl" => 0,
                           "currentQty" => 0,
                           "leverage" => 100
                         }
                       ]}
  @valid_get_positions_response {:ok,
                                 [
                                   %Position{
                                     is_open: false,
                                     realised_pnl: "0",
                                     unrealised_pnl: "0",
                                     current_qty: 0,
                                     leverage: 100
                                   }
                                 ]}

  test "gets positions successfully" do
    Track.Exchanges.BitmexClient.MockAPI
    |> expect(:get_positions, fn _scope, _symbol -> @valid_api_response end)

    assert Position.get_positions(user_scope_fixture(), @symbol) ==
             @valid_get_positions_response
  end
end
