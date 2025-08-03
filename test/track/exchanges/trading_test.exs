defmodule Track.Exchanges.TradingTest do
  alias Track.Exchanges.TradingAPI.Position
  use Track.DataCase
  use ExUnit.Case, async: true
  import Mox
  import Track.AccountsFixtures

  setup :verify_on_exit!

  @trading_module Track.Exchanges.MockTradingAPI
  @symbol "XBTUSD"

  describe "get_positions/3" do
    setup do
      %{scope: user_scope_fixture()}
    end

    test "get positions returns a list of Position", %{scope: scope} do
      @trading_module
      |> expect(:get_positions, fn _scope, _symbol -> [%Position{}] end)

      result = Track.Exchanges.Trading.get_positions(scope, @symbol, @trading_module)

      assert [%Position{} = _position | _] = result
    end

    test "raises with the scope of the wrong type" do
      assert_raise FunctionClauseError, fn ->
        Track.Exchanges.Trading.get_positions(
          %{"user" => "123"},
          @symbol,
          @trading_module
        )
      end
    end

    test "get_positions raises if the symbol is not binary", %{scope: scope} do
      assert_raise FunctionClauseError, fn ->
        Track.Exchanges.Trading.get_positions(
          scope,
          :xbt_usd,
          @trading_module
        )
      end
    end

    test "get_positions raises if the trading_module is not an atom", %{scope: scope} do
      assert_raise FunctionClauseError, fn ->
        Track.Exchanges.Trading.get_positions(
          scope,
          @symbol,
          "not a module"
        )
      end
    end

    test "delegates to the trading module", %{scope: scope} do
      @trading_module
      |> expect(:get_positions, fn _scope, _symbol -> [%Position{}] end)

      result = Track.Exchanges.Trading.get_positions(scope, @symbol, @trading_module)

      assert [%Position{}] == result
    end

    test "in case of no open positions returns empty list", %{scope: scope} do
      @trading_module
      |> expect(:get_positions, fn _scope, _symbol -> [] end)

      result = Track.Exchanges.Trading.get_positions(scope, @symbol, @trading_module)

      assert [] == result
    end

    test "returns position for the given symbol", %{scope: scope} do
      @trading_module
      |> expect(:get_positions, fn _scope, _symbol -> [%Position{symbol: @symbol}] end)

      [result | _] = Track.Exchanges.Trading.get_positions(scope, @symbol, @trading_module)

      assert @symbol == result.symbol
    end

    test "raises when module raises", %{scope: scope} do
      @trading_module
      |> expect(:get_positions, fn _scope, _symbol -> raise "API failure" end)

      assert_raise RuntimeError, fn ->
        Track.Exchanges.Trading.get_positions(scope, @symbol, @trading_module)
      end
    end
  end
end
