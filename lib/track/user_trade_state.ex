defmodule Track.UserTradeState do
  @moduledoc """
  Manages the user's trade state, including balances and position information.
  """

  alias Track.UserTradeState.Balance
  alias Track.UserTradeState.Position

  defstruct [:balance, :positions]

  @moduledoc """
  Manages the user's trade state, including balances and position information.
  """

  alias Track.UserTradeState.Balance
  alias Track.UserTradeState.Position

  @doc """
  Creates a new, empty user trade state.
  """
  def new() do
    %__MODULE__{
      balance: Balance.new(),
      positions: []
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
    updated_positions = Enum.map(bitmex_positions, fn pos -> Position.update(Position.new(), pos, btc_price) end)
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
end
