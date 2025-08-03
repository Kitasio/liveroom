defmodule Track.Exchanges.TradingAPI do
  alias Track.Exchanges.TradingAPI.Position
  alias Track.Accounts.Scope

  @callback get_positions(scope :: Scope, symbol :: String.t()) :: [Position.t()]
end
