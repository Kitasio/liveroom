defmodule Track.Exchanges.Bitmex.MarketData do
  @behaviour Track.Exchanges.MarketDataAPI

  alias Track.Accounts.Scope
  alias Track.Exchanges.MarketDataAPI.Instrument
  alias Track.Exchanges.Bitmex.API

  def get_instrument(%Scope{} = scope, symbol) do
    send_request_to_api(scope, symbol)
    |> parse_response()
  end

  defp send_request_to_api(scope, currency) do
    API.get_instrument(scope, currency)
  end

  defp parse_response({:ok, [response | _tail]}) do
    %{"quoteCurrency" => currency, "lastPrice" => last_price, "symbol" => symbol} = response

    %Instrument{
      currency: currency,
      last_price: to_string(last_price),
      symbol: symbol
    }
  end
end
