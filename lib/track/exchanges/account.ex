defmodule Track.Exchanges.Account do
  alias Track.Accounts.Scope
  alias Track.Exchanges.AccountAPI.Balance

  @spec get_balance(Scope.t(), String.t(), module()) :: Balance.t()
  def get_balance(%Scope{} = scope, currency, account_module) when is_atom(account_module) do
    account_module.get_balance(scope, currency)
  end
end
