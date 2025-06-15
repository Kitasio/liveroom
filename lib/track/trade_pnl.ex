defmodule Track.TradePnl do
  @moduledoc """
  Tracks cumulative PnL across multiple asset trades (buys and sells).
  """

  defmodule Trade do
    defstruct [:side, :amount_usd, :price]
  end

  defmodule State do
    defstruct trades: [],
              # net asset held (+ for long, - for short)
              asset_position: 0.0,
              # USD cost basis for current position
              total_cost: 0.0,
              # Realized PnL from closed parts
              realized_pnl: 0.0
  end

  @type side :: :buy | :sell

  @doc """
  Adds a trade and updates the PnL state.
  """
  def add_trade(%State{} = state, %Trade{side: side, amount_usd: usd, price: price}) do
    asset_amount = usd / price

    case side do
      :buy -> handle_buy(state, usd, asset_amount)
      :sell -> handle_sell(state, usd, asset_amount, price)
    end
  end

  defp handle_buy(
         %State{asset_position: asset_pos, total_cost: cost, trades: trades} = state,
         usd,
         asset_amount
       ) do
    new_asset_pos = asset_pos + asset_amount
    new_cost = cost + usd

    %State{
      state
      | asset_position: new_asset_pos,
        total_cost: new_cost,
        trades: [%Trade{side: :buy, amount_usd: usd, price: usd / asset_amount} | trades]
    }
  end

  defp handle_sell(
         %State{asset_position: asset_pos, total_cost: cost, realized_pnl: realized, trades: trades} =
           state,
         usd,
         asset_amount,
         price
       ) do
    closing_asset = min(asset_amount, asset_pos)
    closing_cost_usd = cost * closing_asset / asset_pos
    revenue_usd = closing_asset * price
    realized_pnl_delta = revenue_usd - closing_cost_usd

    new_asset_pos = asset_pos - closing_asset
    new_cost = cost - closing_cost_usd
    remaining_asset = asset_amount - closing_asset

    # Handle short selling if remaining asset to sell is > 0
    {new_asset_pos, new_cost} =
      if remaining_asset > 0 do
        # For short, we add negative asset and treat revenue as a "credit"
        {
          new_asset_pos - remaining_asset,
          new_cost + remaining_asset * price
        }
      else
        {new_asset_pos, new_cost}
      end

    %State{
      state
      | asset_position: new_asset_pos,
        total_cost: new_cost,
        realized_pnl: realized + realized_pnl_delta,
        trades: [%Trade{side: :sell, amount_usd: usd, price: price} | trades]
    }
  end

  @doc """
  Computes unrealized PnL using current asset price.
  """
  def unrealized_pnl(%State{asset_position: pos}, _current_price) when pos == 0.0, do: 0.0

  def unrealized_pnl(%State{asset_position: asset_pos, total_cost: cost}, current_price) do
    current_value = asset_pos * current_price
    current_value - cost
  end

  @doc """
  Computes total PnL (realized + unrealized).
  """
  def total_pnl(state, current_price) do
    state.realized_pnl + unrealized_pnl(state, current_price)
  end
end
