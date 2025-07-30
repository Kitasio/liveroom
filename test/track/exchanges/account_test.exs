defmodule Track.Exchanges.AccountTest do
  use Track.DataCase
  use ExUnit.Case, async: true
  import Mox
  import Track.AccountsFixtures
  alias Track.Exchanges.AccountAPI.Balance

  setup :verify_on_exit!

  test "delegates get_balance to the given module" do
    currency = "USD"
    valid_response = %Balance{currency: "USD", amount: 69}

    Track.Exchanges.MockAccountAPI
    |> expect(:get_balance, fn _scope, _currency ->
      valid_response
    end)

    assert Track.Exchanges.Account.get_balance(
             user_scope_fixture(),
             currency,
             Track.Exchanges.MockAccountAPI
           ) ==
             valid_response
  end

  test "raises if the last argument is not a module" do
    assert_raise FunctionClauseError, fn ->
      Track.Exchanges.Account.get_balance(
        user_scope_fixture(),
        "USD",
        "binance"
      )
    end
  end
end
