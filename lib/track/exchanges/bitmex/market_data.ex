defmodule Track.Exchanges.Bitmex.MarketData do
  @behaviour Track.Exchanges.MarketDataAPI
  alias Track.Accounts.Scope
  alias Track.Exchanges
  alias Track.Exchanges.MarketDataAPI.Instrument
  alias Track.Exchanges.Bitmex.Request

  def get_instrument(%Scope{} = scope, symbol) do
    params = get_api_config(scope)

    send_request_to_api(params, symbol)
    |> parse_response()
  end

  defp get_api_config(scope) do
    bitmex_settings = Exchanges.get_latest_bitmex_setting!(scope)

    bitmex_base_url =
      Application.get_env(:track, :bitmex_api_base_url, "https://testnet.bitmex.com")

    {bitmex_base_url, bitmex_settings.api_key, bitmex_settings.api_secret}
  end

  defp send_request_to_api({base_url, api_key, api_secret}, symbol) do
    Request.new()
    |> Request.set_api_key(api_key)
    |> Request.set_api_secret(api_secret)
    |> Request.set_method(:get)
    |> Request.set_url(base_url <> "/api/v1/instrument?symbol=#{symbol}")
    |> Request.send()
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
