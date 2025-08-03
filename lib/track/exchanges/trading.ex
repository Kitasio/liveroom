defmodule Track.Exchanges.Trading do
  alias Track.Accounts.Scope

  def get_positions(%Scope{} = scope, symbol, trading_module)
      when is_binary(symbol) and is_atom(trading_module) do
    trading_module.get_positions(scope, symbol)
  end
end
