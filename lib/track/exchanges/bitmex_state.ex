defmodule Track.Exchanges.BitmexState do
  defstruct [:balance, :positions, :margin_info]
  alias Track.Accounts.Scope
  alias Track.BitmexClient
  alias Track.CurrencyConverter
  alias Decimal

  def new() do
    %__MODULE__{
      balance: %{
        usd: nil,
        sats: nil,
        btc: nil
      },
      positions: [],
      margin_info: %{}
    }
  end

  def get_balance(%__MODULE__{} = state, %Scope{} = scope) do
    tasks = [
      fn -> BitmexClient.get_balance(scope) end,
      fn -> BitmexClient.get_instrument(scope) end
    ]

    [balance_result, instrument_result] =
      tasks
      |> Task.async_stream(& &1.(), timeout: 10_000)
      |> Enum.map(fn {:ok, result} -> result end)

    # sats_int is integer
    %{"amount" => sats_int} = balance_result |> hd()
    # btc_price_float is float
    %{"lastPrice" => btc_price_float} = instrument_result |> hd()

    # Use CurrencyConverter to perform conversions and get Decimal values
    # Keep sats as Decimal for the state map
    sats_decimal = Decimal.new(sats_int)
    btc_decimal = CurrencyConverter.sats_to_btc(sats_int)
    usd_decimal = CurrencyConverter.sats_to_usd(sats_int, btc_price_float)

    Map.put(state, :balance, %{usd: usd_decimal, sats: sats_decimal, btc: btc_decimal})
  end

  def get_positions(%__MODULE__{} = state, %Scope{} = scope) do
    tasks = [
      fn -> BitmexClient.get_positions(scope, "XBTUSD") end,
      fn -> BitmexClient.get_instrument(scope) end
    ]

    [positions_result, instrument_result] =
      tasks
      |> Task.async_stream(& &1.(), timeout: 10_000)
      |> Enum.map(fn {:ok, result} -> result end)

    # btc_price_float is float
    %{"lastPrice" => btc_price_float} = instrument_result |> hd()

    positions =
      positions_result
      |> Enum.map(fn position ->
        %{
          "isOpen" => is_open,
          "unrealisedPnl" => unrealised_pnl_sats,
          "realisedPnl" => realised_pnl_sats,
          "leverage" => leverage,
          "currentQty" => current_qty
        } = position

        unrealised_pnl_usd = CurrencyConverter.sats_to_usd(unrealised_pnl_sats, btc_price_float)
        realised_pnl_usd = CurrencyConverter.sats_to_usd(realised_pnl_sats, btc_price_float)

        %{
          is_open: is_open,
          unrealised_pnl: unrealised_pnl_sats,
          unrealised_pnl_usd: unrealised_pnl_usd,
          realised_pnl: realised_pnl_sats,
          realised_pnl_usd: realised_pnl_usd,
          leverage: leverage,
          current_qty: current_qty
        }
      end)

    Map.put(state, :positions, positions)
  end
end
