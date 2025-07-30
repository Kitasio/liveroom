defmodule Track.Exchanges.Bitmex.AccountTest do
  alias Track.Exchanges.AccountAPI.Balance
  use Track.DataCase
  use ExUnit.Case, async: true

  import Mox
  import Track.AccountsFixtures, only: [user_scope_fixture: 0]

  setup :verify_on_exit!

  @currency "XBt"
  @valid_get_balance_api_response {:ok,
                                   [
                                     %{
                                       "account" => 421_399,
                                       "accountId" => 421_399,
                                       "amount" => 18583,
                                       "availableMargin" => 18583,
                                       "currency" => "XBt",
                                       "excessMargin" => 18583,
                                       "foreignMarginBalance" => 0,
                                       "foreignRequirement" => 0,
                                       "grossComm" => 0,
                                       "grossMarkValue" => 0,
                                       "grossOpenCost" => 0,
                                       "grossOpenPremium" => 0,
                                       "initMargin" => 0,
                                       "maintMargin" => 0,
                                       "marginBalance" => 18583,
                                       "marginLeverage" => 0,
                                       "marginUsedPcnt" => 0,
                                       "realisedPnl" => 0,
                                       "riskLimit" => 1_000_000_000_000,
                                       "riskValue" => 0,
                                       "targetExcessMargin" => 18583,
                                       "timestamp" => "2025-07-10T12:00:00.040Z",
                                       "unrealisedPnl" => 0,
                                       "walletBalance" => 18583,
                                       "withdrawableMargin" => 18583
                                     }
                                   ]}

  test "gets account balance" do
    Track.Exchanges.Bitmex.MockAPI
    |> expect(:get_balance, fn _scope, _currency -> @valid_get_balance_api_response end)

    valid_result = %Balance{currency: "XBt", amount: "18583"}

    assert Track.Exchanges.Bitmex.Account.get_balance(user_scope_fixture(), @currency) ==
             valid_result
  end
end
