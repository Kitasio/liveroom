defmodule Track.Exchanges.Bitmex.Account do
  @behaviour Track.Exchanges.AccountAPI

  alias Track.Exchanges
  alias Track.Accounts.Scope
  alias Track.Exchanges.AccountAPI.Balance
  alias Track.Exchanges.Bitmex.Request

  @impl true
  def get_balance(%Scope{} = scope, currency) do
    params = get_api_config(scope)

    send_request_to_api(params, currency)
    |> parse_response()
  end

  defp get_api_config(scope) do
    bitmex_settings = Exchanges.get_latest_bitmex_setting!(scope)

    bitmex_base_url =
      Application.get_env(:track, :bitmex_api_base_url, "https://testnet.bitmex.com")

    {bitmex_base_url, bitmex_settings.api_key, bitmex_settings.api_secret}
  end

  defp send_request_to_api({base_url, api_key, api_secret}, currency) do
    Request.new()
    |> Request.set_api_key(api_key)
    |> Request.set_api_secret(api_secret)
    |> Request.set_method(:get)
    |> Request.set_url(base_url <> "/api/v1/user/margin?currency=#{currency}")
    |> Request.send()
  end

  defp parse_response({:ok, [response | _tail]}) do
    %{"currency" => currency, "amount" => amount} = response

    %Balance{currency: to_string(currency), amount: to_string(amount)}
  end
end
