defmodule Track.Exchanges.Account do
  alias Track.Accounts.Scope
  alias Track.Exchanges.AccountAPI.Balance

  @spec get_balance(module(), Scope.t(), String.t()) :: Balance.t()
  def get_balance(account_module, %Scope{} = scope, currency) do
    account_module.get_balance(scope, currency)
  end
end
