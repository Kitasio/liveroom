defmodule Track.UserTradeState.Balance do
  @moduledoc """
  Manages the user's balances in different units.
  """

  defstruct [:balance_usd, :balance_sats, :balance_btc]

  @doc """
  Creates a new, empty balance state.
  """
  def new() do
    %__MODULE__{
      balance_usd: 0,
      balance_sats: 0,
      balance_btc: 0
    }
  end

  @doc """
  Gets the balance in the specified unit.

  Defaults to `:sats`.

  ## Examples

      iex> balance = %Track.UserTradeState.Balance{balance_sats: 100_000, balance_usd: 50, balance_btc: 0.001}
      iex> Track.UserTradeState.Balance.get_balance(balance, :sats)
      100_000
      iex> Track.UserTradeState.Balance.get_balance(balance, :usd)
      50
      iex> Track.UserTradeState.Balance.get_balance(balance, :btc)
      0.001
      iex> Track.UserTradeState.Balance.get_balance(balance)
      100_000
  """
  def get_balance(%__MODULE__{balance_sats: sats}, :sats), do: sats
  def get_balance(%__MODULE__{balance_usd: usd}, :usd), do: usd
  def get_balance(%__MODULE__{balance_btc: btc}, :btc), do: btc
  def get_balance(%__MODULE__{} = balance), do: get_balance(balance, :sats)

  @doc """
  Updates the balance in the balance state.

  Accepts a tuple `{:unit, balance}` where unit is `:sats` or `:btc`.
  Does not update the USD balance.
  """
  def update_balance(%__MODULE__{} = balance, {:sats, new_balance}) do
    %__MODULE__{
      balance
      | balance_sats: new_balance,
        balance_btc: sats_to_btc(new_balance)
    }
  end

  def update_balance(%__MODULE__{} = balance, {:btc, new_balance}) do
    %__MODULE__{
      balance
      | balance_btc: new_balance,
        balance_sats: btc_to_sats(new_balance)
    }
  end

  @doc """
  Updates the balance in the balance state, including the USD balance.

  Accepts a tuple `{:unit, balance}` where unit is `:sats` or `:btc`,
  and the current BTC price in USD.
  """
  def update_balance(%__MODULE__{} = balance, {:sats, new_balance}, btc_price) do
    %__MODULE__{
      balance
      | balance_sats: new_balance,
        balance_usd: sats_to_usd(new_balance, btc_price),
        balance_btc: sats_to_btc(new_balance)
    }
  end

  def update_balance(%__MODULE__{} = balance, {:btc, new_balance}, btc_price) do
    %__MODULE__{
      balance
      | balance_btc: new_balance,
        balance_usd: btc_to_usd(new_balance, btc_price),
        balance_sats: btc_to_sats(new_balance)
    }
  end

  @doc false
  def sats_to_usd(sats, btc_price) do
    usd_value = sats / 100_000_000 * btc_price
    round(usd_value)
  end

  @doc false
  def sats_to_btc(sats) do
    sats / 100_000_000
  end

  @doc false
  def btc_to_usd(btc, btc_price) do
    btc * btc_price
  end

  @doc false
  def btc_to_sats(btc) do
    btc * 100_000_000
  end

  @doc """
  Calculates maximum buy size based on available margin and leverage.
  
  Takes available margin in satoshis, leverage multiplier, and BTC price.
  Returns max buy size in USD.
  """
  def calculate_max_buy_size(available_margin_sats, leverage, btc_price) when available_margin_sats > 0 and leverage > 0 do
    # Convert available margin to USD
    available_margin_usd = sats_to_usd(available_margin_sats, btc_price)
    
    # Max buy size = available margin * leverage * safety factor (0.95 to account for fees/slippage)
    max_size = available_margin_usd * leverage * 0.95
    round(max_size)
  end

  def calculate_max_buy_size(_, _, _), do: 0

  @doc """
  Calculates maximum sell size based on available margin, leverage, and current position.
  
  Takes available margin in satoshis, leverage multiplier, BTC price, and current position quantity.
  Returns max sell size in USD.
  """
  def calculate_max_sell_size(available_margin_sats, leverage, btc_price, current_position_qty \\ 0) when available_margin_sats > 0 and leverage > 0 do
    # Convert available margin to USD
    available_margin_usd = sats_to_usd(available_margin_sats, btc_price)
    
    # Base max size calculation
    base_max_size = available_margin_usd * leverage * 0.95
    
    # If we have a long position, we can sell more (close position + open short)
    # If we have a short position, we have less margin available for additional shorts
    position_adjustment = if current_position_qty > 0, do: current_position_qty * 0.1, else: 0
    
    max_size = base_max_size + position_adjustment
    round(max_size)
  end

  def calculate_max_sell_size(_, _, _, _), do: 0
end
