defmodule Track.Exchanges.AccountAPI do
  alias Track.Exchanges.AccountAPI.Balance
  alias Track.Accounts.Scope

  @callback get_balance(scope :: Scope.t(), currency :: String.t()) :: Balance.t()
end
