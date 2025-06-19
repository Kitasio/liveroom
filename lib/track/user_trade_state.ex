defmodule Track.UserTradeState do
  @moduledoc """
  Manages the user's trade state, including balances in different units and PnL.
  """
  alias Track.UserTradeState

  defstruct [
    :balance_usd,
    :balance_sats,
    :balance_btc,
    :unrealised_pnl,
    :realised_pnl,
    :position_open
  ]

  @doc """
  Creates a new, empty user trade state.
  """
  def new() do
    %UserTradeState{
      balance_usd: 0,
      balance_sats: 0,
      balance_btc: 0,
      unrealised_pnl: 0,
      realised_pnl: 0,
      position_open: false
    }
  end

  def update_position(%UserTradeState{} = state, bitmex_position, btc_price) do
    %{"isOpen" => position_open, "unrealisedPnl" => unrealised_pnl, "realisedPnl" => realised_pnl} =
      bitmex_position

    %UserTradeState{
      state
      | unrealised_pnl: sats_to_usd(unrealised_pnl, btc_price) |> round(),
        realised_pnl: sats_to_usd(realised_pnl, btc_price) |> round(),
        position_open: position_open
    }
  end

  @doc """
  Gets the balance in the specified unit.

  Defaults to `:sats`.
  """
  def get_balance(%UserTradeState{balance_sats: sats}, :sats), do: sats
  def get_balance(%UserTradeState{balance_usd: usd}, :usd), do: usd
  def get_balance(%UserTradeState{balance_btc: btc}, :btc), do: btc
  def get_balance(%UserTradeState{} = state), do: get_balance(state, :sats)

  @doc """
  Updates the balance in the user trade state.

  Accepts a tuple `{:unit, balance}` where unit is `:sats` or `:btc`.
  Does not update the USD balance.
  """
  def update_balance(%UserTradeState{} = state, {:sats, balance}) do
    %UserTradeState{
      state
      | balance_sats: balance,
        balance_btc: sats_to_btc(balance)
    }
  end

  def update_balance(%UserTradeState{} = state, {:btc, balance}) do
    %UserTradeState{
      state
      | balance_btc: balance,
        balance_sats: btc_to_sats(balance)
    }
  end

  @doc """
  Updates the balance in the user trade state, including the USD balance.

  Accepts a tuple `{:unit, balance}` where unit is `:sats` or `:btc`,
  and the current BTC price in USD.
  """
  def update_balance(%UserTradeState{} = state, {:sats, balance}, btc_price) do
    %UserTradeState{
      state
      | balance_sats: balance,
        balance_usd: sats_to_usd(balance, btc_price),
        balance_btc: sats_to_btc(balance)
    }
  end

  def update_balance(%UserTradeState{} = state, {:btc, balance}, btc_price) do
    %UserTradeState{
      state
      | balance_btc: balance,
        balance_usd: btc_to_usd(balance, btc_price),
        balance_sats: btc_to_sats(balance)
    }
  end

  @doc false
  defp sats_to_usd(sats, btc_price) do
    usd_value = sats / 100_000_000 * btc_price
    round(usd_value)
  end

  @doc false
  defp sats_to_btc(sats) do
    sats / 100_000_000
  end

  @doc false
  defp btc_to_usd(btc, btc_price) do
    btc * btc_price
  end

  @doc false
  defp btc_to_sats(btc) do
    btc * 100_000_000
  end
end
