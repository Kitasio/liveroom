defmodule Track.Exchanges.BitmexStateTest do
  alias Track.Exchanges.BitmexState.Balance
  alias Track.Exchanges.BitmexState
  use Track.DataCase
  use ExUnit.Case, async: true

  @valid_sats "18583"
  @valid_btc "0.00018583"
  @valid_usd "16.91034417"

  @valid_state_set_balance_result %BitmexState{
    balance: %Balance{sats: @valid_sats, btc: @valid_btc, usd: @valid_usd},
    positions: [],
    margin_info: %{max_buy_size_usd: 0, max_sell_size_usd: 0},
    open_orders: []
  }

  test "sets balance for the state" do
    balance =
      Balance.new()
      |> Balance.update_sats(@valid_sats)
      |> Balance.update_btc(@valid_btc)
      |> Balance.update_usd(@valid_usd)

    assert BitmexState.new() |> BitmexState.set_balance(balance) ==
             @valid_state_set_balance_result
  end
end
