defmodule Track.Exchanges.BitmexState.BalanceTest do
  alias Track.Exchanges.BitmexState.Balance
  alias Track.Exchanges.BitmexState
  use Track.DataCase
  use ExUnit.Case, async: true

  import Mox
  import Track.AccountsFixtures, only: [user_scope_fixture: 0]

  setup :verify_on_exit!
  @valid_get_instrument_api_response {:ok, [%{"lastPrice" => 90999}]}
  @valid_get_balance_api_response {:ok,
                                   [
                                     %{
                                       "amount" => 18583
                                     }
                                   ]}

  @valid_fetch_balance_response %Balance{sats: "18583", btc: "0.00018583", usd: "16.91034417"}

  test "fetches user balance" do
    Track.Exchanges.BitmexClient.MockAPI
    |> expect(:get_instrument, fn _scope, _symbol -> @valid_get_instrument_api_response end)
    |> expect(:get_balance, fn _scope, _currency -> @valid_get_balance_api_response end)

    assert BitmexState.Balance.fetch_balance(user_scope_fixture()) ==
             @valid_fetch_balance_response
  end
end
