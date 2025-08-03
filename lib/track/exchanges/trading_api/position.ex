defmodule Track.Exchanges.TradingAPI.Position do
  @type t :: %__MODULE__{
          symbol: String.t() | nil,
          current_qty: integer() | nil,
          is_open: boolean() | nil,
          leverage: integer() | nil,
          realised_pnl: String.t() | nil,
          unrealised_pnl: String.t() | nil
        }

  defstruct [:symbol, :current_qty, :is_open, :leverage, :realised_pnl, :unrealised_pnl]
end
