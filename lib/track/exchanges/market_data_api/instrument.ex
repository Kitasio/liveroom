defmodule Track.Exchanges.MarketDataAPI.Instrument do
  @type t :: %__MODULE__{
          symbol: String.t(),
          currency: String.t(),
          last_price: String.t()
        }

  @enforce_keys [:symbol, :currency, :last_price]
  defstruct [:symbol, :currency, :last_price]
end
