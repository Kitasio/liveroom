defmodule Track.Exchanges.BitmexClient.APIImpl do
  alias Track.Exchanges
  alias Track.Accounts.Scope
  alias Track.Exchanges.BitmexClient.Request

  @behaviour Track.Exchanges.BitmexClient.API

  @impl true
  def get_balance(%Scope{} = scope, currency) do
    {base_url, api_key, api_secret} = get_api_config(scope)

    Request.new()
    |> Request.set_api_key(api_key)
    |> Request.set_api_secret(api_secret)
    |> Request.set_method(:get)
    |> Request.set_url(base_url <> "/api/v1/user/margin?currency=#{currency}")
    |> Request.send()
  end

  @impl true
  def get_instrument(%Scope{} = scope, symbol \\ "XBTUSD") do
    {base_url, api_key, api_secret} = get_api_config(scope)

    Request.new()
    |> Request.set_api_key(api_key)
    |> Request.set_api_secret(api_secret)
    |> Request.set_method(:get)
    |> Request.set_url(base_url <> "/api/v1/instrument?symbol=#{symbol}")
    |> Request.send()
  end

  @impl true
  def get_positions(%Scope{} = scope, symbol \\ "XBTUSD") do
    {base_url, api_key, api_secret} = get_api_config(scope)

    Request.new()
    |> Request.set_api_key(api_key)
    |> Request.set_api_secret(api_secret)
    |> Request.set_method(:get)
    |> Request.set_url(base_url <> "/api/v1/position?symbol=#{symbol}")
    |> Request.send()
  end

  @impl true
  def place_market_order(%Scope{} = scope, symbol, side, quantity) do
    {base_url, api_key, api_secret} = get_api_config(scope)

    body = %{
      "symbol" => symbol,
      "orderQty" => quantity,
      "side" => side,
      "ordType" => "Market"
    }

    Request.new()
    |> Request.set_api_key(api_key)
    |> Request.set_api_secret(api_secret)
    |> Request.set_method(:post)
    |> Request.set_url(base_url <> "/api/v1/order")
    |> Request.set_and_encode_body(body)
    |> Request.send()
  end

  defp get_api_config(scope) do
    bitmex_settings = Exchanges.get_latest_bitmex_setting!(scope)

    bitmex_base_url =
      Application.get_env(:track, :bitmex_api_base_url, "https://testnet.bitmex.com")

    {bitmex_base_url, bitmex_settings.api_key, bitmex_settings.api_secret}
  end
end
