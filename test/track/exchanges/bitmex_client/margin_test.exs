defmodule Track.Exchanges.BitmexClient.MarginTest do
  use Track.DataCase
  use ExUnit.Case, async: true

  import Mox
  import Track.AccountsFixtures, only: [user_scope_fixture: 0]

  setup :verify_on_exit!

  @currency "XBt"
  @valid_api_response {:ok,
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

  @valid_margin_balance_response {:ok,
                                  [
                                    %Track.Exchanges.BitmexClient.Margin{
                                      account: 421_399,
                                      account_id: 421_399,
                                      amount: 18583,
                                      available_margin: 18583,
                                      currency: "XBt",
                                      excess_margin: 18583,
                                      foreign_margin_balance: 0,
                                      foreign_requirement: 0,
                                      gross_comm: 0,
                                      gross_mark_value: 0,
                                      gross_open_cost: 0,
                                      gross_open_premium: 0,
                                      init_margin: 0,
                                      maint_margin: 0,
                                      margin_balance: 18583,
                                      margin_leverage: 0,
                                      margin_used_pcnt: 0,
                                      realised_pnl: 0,
                                      risk_limit: 1_000_000_000_000,
                                      risk_value: 0,
                                      target_excess_margin: 18583,
                                      timestamp: "2025-07-10T12:00:00.040Z",
                                      unrealised_pnl: 0,
                                      wallet_balance: 18583,
                                      withdrawable_margin: 18583
                                    }
                                  ]}

  test "gets user margin balance" do
    Track.Exchanges.BitmexClient.MockAPI
    |> expect(:get_balance, fn _scope, _currency -> @valid_api_response end)

    assert Track.Exchanges.BitmexClient.Margin.get_user_balance(user_scope_fixture(), @currency) ==
             @valid_margin_balance_response
  end
end
