defmodule Track.UserTradeState.Position do
  @moduledoc """
  Manages the user's position information.
  """

  defstruct [:is_open, :unrealised_pnl, :realised_pnl, :leverage, :current_qty]

  alias Track.UserTradeState.Balance

  @doc """
  Creates a new, empty position state.
  """
  def new() do
    %__MODULE__{
      is_open: false,
      unrealised_pnl: 0,
      realised_pnl: 0,
      leverage: 0,
      current_qty: 0
    }
  end

  @doc """
  Updates the position information from BitMEX data.

  Takes the current position struct, a BitMEX position map, and the current BTC price,
  and returns an updated position struct with the latest data including PnL values
  converted to USD.
  """
  def update(%__MODULE__{} = position, bitmex_position, btc_price) do
    %{
      "isOpen" => is_open,
      "unrealisedPnl" => unrealised_pnl,
      "realisedPnl" => realised_pnl,
      "leverage" => leverage,
      "currentQty" => current_qty
    } = bitmex_position

    %__MODULE__{
      position
      | is_open: is_open,
        unrealised_pnl: Balance.sats_to_usd(unrealised_pnl, btc_price) |> round(),
        realised_pnl: Balance.sats_to_usd(realised_pnl, btc_price) |> round(),
        leverage: leverage,
        current_qty: current_qty
    }
  end
end
