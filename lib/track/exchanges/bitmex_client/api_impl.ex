defmodule Track.Exchanges.BitmexClient.APIImpl do
  alias Track.Exchanges
  alias Track.Accounts.Scope
  alias Track.Exchanges.BitmexClient.Request

  @behaviour Track.Exchanges.BitmexClient.API

  @impl true
  def get_balance(%Scope{} = scope, currency) do
    bitmex_settings = Exchanges.get_latest_bitmex_setting!(scope)

    bitmex_base_url =
      Application.get_env(:track, :bitmex_api_base_url, "https://testnet.bitmex.com")

    Request.new()
    |> Request.set_api_key(bitmex_settings.api_key)
    |> Request.set_api_secret(bitmex_settings.api_secret)
    |> Request.set_method(:get)
    |> Request.set_url(bitmex_base_url <> "/api/v1/user/margin?currency=#{currency}")
    |> Request.send()
  end
end
