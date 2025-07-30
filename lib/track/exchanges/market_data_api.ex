defmodule Track.Exchanges.MarketDataAPI do
  alias Track.Exchanges.MarketDataAPI.Instrument
  alias Track.Accounts.Scope

  @callback get_instrument(scope :: Scope.t(), symbol :: String.t()) :: Instrument.t()
end
