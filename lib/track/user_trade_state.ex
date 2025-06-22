defmodule Track.UserTradeState do
  @moduledoc """
  Manages the user's trade state, including balances and position information.
  """

  alias Track.UserTradeState.Balance
  alias Track.UserTradeState.Position

  defstruct [:balance, :positions, :margin_info]

  alias Track.UserTradeState.Balance
  alias Track.UserTradeState.Position

  @doc """
  Creates a new, empty user trade state.
  """
  def new() do
    %__MODULE__{
      balance: Balance.new(),
      positions: [],
      margin_info: %{}
    }
  end

  @doc """
  Updates the user's position information from a list of BitMEX position maps.

  Takes the current trade state, a list of BitMEX position maps, and the current BTC price,
  and returns an updated state with the latest position data. PnL values are
  converted to USD within the nested position structs.

  ## Examples

      iex> state = Track.UserTradeState.new()
      iex> positions_data = [%{"isOpen" => true, "unrealisedPnl" => 1000, "realisedPnl" => 500, "leverage" => 10, "currentQty" => 100}]
      iex> updated = Track.UserTradeState.update_positions(state, positions_data, 50000)
      iex> [position | _] = updated.positions
      iex> position.is_open
      true
      iex> position.unrealised_pnl
      5

  """
  def update_positions(%__MODULE__{} = state, bitmex_positions, btc_price) do
    updated_positions =
      Enum.map(bitmex_positions, fn pos -> Position.update(Position.new(), pos, btc_price) end)

    %__MODULE__{
      state
      | positions: updated_positions
    }
  end

  @doc """
  Gets the balance in the specified unit from the nested Balance struct.

  Defaults to `:sats`.

  Delegates to `Track.UserTradeState.Balance.get_balance/2`.
  """
  def get_balance(%__MODULE__{balance: balance}, unit \\ :sats) do
    Balance.get_balance(balance, unit)
  end

  @doc """
  Updates the balance in the nested Balance struct.

  Accepts a tuple `{:unit, balance}` where unit is `:sats` or `:btc`.
  Does not update the USD balance.

  Delegates to `Track.UserTradeState.Balance.update_balance/2`.
  """
  def update_balance(%__MODULE__{} = state, balance_tuple) do
    %__MODULE__{
      state
      | balance: Balance.update_balance(state.balance, balance_tuple)
    }
  end

  @doc """
  Updates the balance in the nested Balance struct, including the USD balance.

  Accepts a tuple `{:unit, balance}` where unit is `:sats` or `:btc`,
  and the current BTC price in USD.

  Delegates to `Track.UserTradeState.Balance.update_balance/3`.
  """
  def update_balance(%__MODULE__{} = state, balance_tuple, btc_price) do
    %__MODULE__{
      state
      | balance: Balance.update_balance(state.balance, balance_tuple, btc_price)
    }
  end

  @doc """
  Updates the margin information from BitMEX margin data.

  Takes the current trade state and BitMEX margin response map.
  """
  def update_margin_info(%__MODULE__{} = state, margin_data) when is_map(margin_data) do
    %__MODULE__{
      state
      | margin_info: margin_data
    }
  end

  @doc """
  Calculates maximum buy size based on current margin and position data.

  Returns max buy size in USD.
  """
  def get_max_buy_size(%__MODULE__{} = state, btc_price) do
    available_margin = Map.get(state.margin_info, "availableMargin", 0)
    leverage = get_effective_leverage(state)

    Balance.calculate_max_buy_size(available_margin, leverage, btc_price)
  end

  @doc """
  Calculates maximum sell size based on current margin and position data.

  Returns max sell size in USD.
  """
  def get_max_sell_size(%__MODULE__{} = state, btc_price) do
    available_margin = Map.get(state.margin_info, "availableMargin", 0)
    leverage = get_effective_leverage(state)
    current_qty = get_current_position_qty(state)

    Balance.calculate_max_sell_size(available_margin, leverage, btc_price, current_qty)
  end

  # Private helper functions
  defp get_effective_leverage(%__MODULE__{positions: positions}) do
    case positions do
      [%Position{leverage: leverage} | _] when leverage > 0 -> leverage
      # Default to 1x if no position or leverage info
      _ -> 1
    end
  end

  defp get_current_position_qty(%__MODULE__{positions: positions}) do
    case positions do
      [%Position{current_qty: qty} | _] -> qty
      _ -> 0
    end
  end
end
