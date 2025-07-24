defmodule Track.Exchanges.BitmexState do
  defstruct [:balance, :positions, :margin_info, :open_orders]
  alias Track.Exchanges.BitmexClient.Instrument
  alias Track.Exchanges.BitmexClient.Margin
  alias Track.Accounts.Scope
  alias Track.BitmexClient
  alias Track.CurrencyConverter
  alias Decimal

  def new() do
    %__MODULE__{
      balance: %{
        usd: 0,
        sats: 0,
        btc: 0
      },
      positions: [],
      margin_info: %{
        max_buy_size_usd: 0,
        max_sell_size_usd: 0
      },
      open_orders: []
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
    |> get_open_orders(scope)
    |> get_margin_info(scope)
  end

  @doc """
  Fetches the user's margin balance and instrument price and updates the state.
  """
  def get_balance(%__MODULE__{} = state, %Scope{} = scope) do
    {sats_balance, btc_price} = get_balance_and_price(scope)

    Map.put(state, :balance, %{
      usd: CurrencyConverter.sats_to_usd(sats_balance, btc_price),
      sats: to_string(sats_balance),
      btc: CurrencyConverter.sats_to_btc(sats_balance)
    })
  end

  defp get_balance_and_price(scope) do
    tasks = [
      fn -> Margin.get_user_balance(scope, "XBt") end,
      fn -> Instrument.get_instrument(scope) end
    ]

    [balance_result, instrument_result] =
      tasks
      |> Task.async_stream(& &1.(), timeout: 10_000)
      |> Enum.map(fn {:ok, result} -> result end)

    {:ok, [%{amount: sats_int} | _tail]} = balance_result
    {:ok, [%{last_price: btc_price_float} | _tail]} = instrument_result

    {sats_int, btc_price_float}
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

  @doc """
  Fetches active open orders and updates the state.
  """
  def get_open_orders(%__MODULE__{} = state, %Scope{} = scope) do
    open_orders = BitmexClient.get_open_orders(scope)
    Map.put(state, :open_orders, open_orders)
  end

  # Private helper functions for margin calculations

  # Gets the effective leverage from the state's positions.
  defp get_effective_leverage(%__MODULE__{positions: positions}) do
    case positions do
      [%{leverage: leverage} | _] when leverage > 0 -> leverage
      # Default to 1x if no position or leverage info
      _ -> 1
    end
  end

  # Gets the current position quantity from the state's positions.
  defp get_current_position_qty(%__MODULE__{positions: positions}) do
    case positions do
      [%{current_qty: qty} | _] -> qty
      _ -> 0
    end
  end

  # Calculates maximum buy size in USD based on available margin, leverage, and BTC price.
  defp calculate_max_buy_size_usd(available_margin_sats, leverage, btc_price_usd_string)
       when (is_integer(available_margin_sats) or is_binary(available_margin_sats)) and
              (is_number(leverage) or is_struct(leverage, Decimal)) and
              is_binary(btc_price_usd_string) do
    # Convert available margin to USD using the price string
    available_margin_usd_string =
      CurrencyConverter.sats_to_usd(available_margin_sats, btc_price_usd_string)

    available_margin_usd_decimal = Decimal.new(available_margin_usd_string)

    leverage_decimal = Decimal.new(leverage)
    safety_factor = Decimal.new("0.95")

    # Max buy size = available margin USD * leverage * safety factor
    max_size_usd = Decimal.mult(available_margin_usd_decimal, leverage_decimal)
    max_size_usd = Decimal.mult(max_size_usd, safety_factor)

    # Round to integer USD value and return as string
    Decimal.round(max_size_usd) |> Decimal.to_string()
  end

  # Handle invalid inputs
  defp calculate_max_buy_size_usd(_, _, _), do: "0"

  # Calculates maximum sell size in USD based on available margin, leverage, BTC price, risk value, and current position.
  defp calculate_max_sell_size_usd(
         available_margin_sats,
         leverage,
         btc_price_usd_string,
         risk_value_sats,
         current_qty
       )
       when (is_integer(available_margin_sats) or is_binary(available_margin_sats)) and
              (is_number(leverage) or is_struct(leverage, Decimal)) and
              is_binary(btc_price_usd_string) and
              (is_integer(risk_value_sats) or is_binary(risk_value_sats)) and
              is_integer(current_qty) do
    # Convert available margin to USD
    available_margin_usd_string =
      CurrencyConverter.sats_to_usd(available_margin_sats, btc_price_usd_string)

    available_margin_usd_decimal = Decimal.new(available_margin_usd_string)

    leverage_decimal = Decimal.new(leverage)
    safety_factor = Decimal.new("0.95")

    # Base max size calculation
    base_max_size_usd = Decimal.mult(available_margin_usd_decimal, leverage_decimal)
    base_max_size_usd = Decimal.mult(base_max_size_usd, safety_factor)

    # If we have a long position, add the USD value of the position to sell capacity
    position_adjustment_usd_decimal =
      if current_qty > 0 do
        risk_value_usd_string =
          CurrencyConverter.sats_to_usd(risk_value_sats, btc_price_usd_string)

        risk_value_usd_decimal = Decimal.new(risk_value_usd_string)
        risk_value_usd_decimal
      else
        Decimal.new("0")
      end

    max_size_usd = Decimal.add(base_max_size_usd, position_adjustment_usd_decimal)

    # Round to integer USD value and return as string
    Decimal.round(max_size_usd) |> Decimal.to_string()
  end

  # Handle invalid inputs
  defp calculate_max_sell_size_usd(_, _, _, _, _), do: "0"

  @doc """
  Fetches detailed margin information and updates the state with calculated max trade sizes.
  """
  def get_margin_info(%__MODULE__{} = state, %Scope{} = scope) do
    margin_data = BitmexClient.get_margin_info(scope)

    available_margin_sats = Map.get(margin_data, "availableMargin", 0)
    risk_value_sats = Map.get(margin_data, "riskValue", 0)

    # Get BTC price from state (should be available after get_balance/get_positions)
    btc_price_usd_string = get_btc_price_from_state(state)

    # Get leverage and current quantity from state positions
    leverage = get_effective_leverage(state)
    current_qty = get_current_position_qty(state)

    # Calculate max buy and sell sizes in USD
    max_buy_size_usd =
      calculate_max_buy_size_usd(available_margin_sats, leverage, btc_price_usd_string)

    max_sell_size_usd =
      calculate_max_sell_size_usd(
        available_margin_sats,
        leverage,
        btc_price_usd_string,
        risk_value_sats,
        current_qty
      )

    # Update state with calculated values
    margin_info =
      state.margin_info
      |> Map.put(:max_buy_size_usd, max_buy_size_usd)
      |> Map.put(:max_sell_size_usd, max_sell_size_usd)

    Map.put(state, :margin_info, margin_info)
  end
end
