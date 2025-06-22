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

  @doc """
  Fetches the latest Bitmex state (balance, positions, margin info) for a given scope.

  Options:
    - `:force_fetch_price` (boolean): If true, forces fetching the BTC price
      from the API even if it's available in the state's balance. Defaults to false.
  """
  def get_state(%Scope{} = scope, opts \\ []) do
    new()
    |> get_balance(scope)
    |> get_positions(scope, opts)

    # Add get_margin_info here when implemented
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

  def get_positions(%__MODULE__{} = state, %Scope{} = scope, opts \\ []) do
    force_fetch_price = Keyword.get(opts, :force_fetch_price, false)

    btc_price =
      if force_fetch_price do
        # Force fetch the instrument price
        {:ok, [instrument_result | _]} = BitmexClient.get_instrument(scope)
        %{"lastPrice" => btc_price_float} = instrument_result
        Decimal.new(btc_price_float)
      else
        # Try to get price from state, otherwise fetch
        case get_btc_price_from_state(state) do
          nil ->
            {:ok, [instrument_result | _]} = BitmexClient.get_instrument(scope)
            %{"lastPrice" => btc_price_float} = instrument_result
            Decimal.new(btc_price_float)

          price ->
            price
        end
      end

    positions_list = BitmexClient.get_positions(scope, "XBTUSD")

    positions =
      positions_list
      |> Enum.map(fn position ->
        %{
          "isOpen" => is_open,
          "unrealisedPnl" => unrealised_pnl_sats,
          "realisedPnl" => realised_pnl_sats,
          "leverage" => leverage,
          "currentQty" => current_qty
        } = position

        # Use the obtained btc_price (Decimal) for conversions
        unrealised_pnl_usd = CurrencyConverter.sats_to_usd(unrealised_pnl_sats, btc_price)
        realised_pnl_usd = CurrencyConverter.sats_to_usd(realised_pnl_sats, btc_price)

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

  # Helper to derive BTC price from state balance if available
  defp get_btc_price_from_state(%__MODULE__{balance: %{usd: usd, btc: btc}})
       when is_struct(usd, Decimal) and is_struct(btc, Decimal) do
    if Decimal.compare(usd, 0) == :gt and Decimal.compare(btc, 0) == :gt do
      Decimal.div(usd, btc)
    else
      nil
    end
  end

  defp get_btc_price_from_state(_), do: nil
end
