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

    # Use CurrencyConverter to perform conversions and get string values
    sats_string = sats_int |> to_string()
    btc_string = CurrencyConverter.sats_to_btc(sats_int)
    usd_string = CurrencyConverter.sats_to_usd(sats_int, btc_price_float)

    Map.put(state, :balance, %{usd: usd_string, sats: sats_string, btc: btc_string})
  end

  def get_positions(%__MODULE__{} = state, %Scope{} = scope, opts \\ []) do
    force_fetch_price = Keyword.get(opts, :force_fetch_price, false)

    btc_price_source =
      if force_fetch_price do
        # Force fetch the instrument price
        {:ok, [instrument_result | _]} = BitmexClient.get_instrument(scope)
        %{"lastPrice" => btc_price_float} = instrument_result
        btc_price_float
      else
        # Try to get price from state, otherwise fetch
        case get_btc_price_from_state(state) do
          nil ->
            {:ok, [instrument_result | _]} = BitmexClient.get_instrument(scope)
            %{"lastPrice" => btc_price_float} = instrument_result
            btc_price_float

          price_string ->
            # CurrencyConverter expects numeric types or Decimal for price
            # Attempt to parse the string price back to Decimal for conversion
            case Decimal.new(price_string) do
              %Decimal{} = price_decimal -> price_decimal
              # Should not happen if get_btc_price_from_state returns valid string
              _ -> nil
            end
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

        # Use the obtained btc_price_source (float or Decimal) for conversions
        unrealised_pnl_usd = CurrencyConverter.sats_to_usd(unrealised_pnl_sats, btc_price_source)
        realised_pnl_usd = CurrencyConverter.sats_to_usd(realised_pnl_sats, btc_price_source)

        %{
          is_open: is_open,
          unrealised_pnl: unrealised_pnl_sats |> to_string(),
          unrealised_pnl_usd: unrealised_pnl_usd,
          realised_pnl: realised_pnl_sats |> to_string(),
          realised_pnl_usd: realised_pnl_usd,
          leverage: leverage,
          current_qty: current_qty
        }
      end)

    Map.put(state, :positions, positions)
  end

  # Helper to derive BTC price (as string) from state balance if available
  defp get_btc_price_from_state(%__MODULE__{balance: %{usd: usd_str, btc: btc_str}})
       when is_binary(usd_str) and is_binary(btc_str) do
    case {Decimal.new(usd_str), Decimal.new(btc_str)} do
      {%Decimal{} = usd, %Decimal{} = btc} ->
        if Decimal.compare(usd, 0) == :gt and Decimal.compare(btc, 0) == :gt do
          Decimal.div(usd, btc) |> Decimal.to_string()
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp get_btc_price_from_state(_), do: nil
end
