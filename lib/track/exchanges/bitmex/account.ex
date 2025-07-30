defmodule Track.Exchanges.Bitmex.Account do
  @behaviour Track.Exchanges.AccountAPI

  alias Track.Accounts.Scope
  alias Track.Exchanges.AccountAPI.Balance
  alias Track.Exchanges.Bitmex.API

  @impl true
  def get_balance(%Scope{} = scope, currency) do
    send_request_to_api(scope, currency)
    |> parse_response()
  end

  defp send_request_to_api(scope, currency) do
    API.get_balance(scope, currency)
  end

  defp parse_response({:ok, [response | _tail]}) do
    %{"currency" => currency, "amount" => amount} = response

    %Balance{currency: to_string(currency), amount: to_string(amount)}
  end
end
