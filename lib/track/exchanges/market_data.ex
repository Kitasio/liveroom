defmodule Track.Exchanges.MarketData do
  def get_instrument(scope, symbol, market_data_module) when is_atom(market_data_module) do
    market_data_module.get_instrument(scope, symbol)
  end
end
