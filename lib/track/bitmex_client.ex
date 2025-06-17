defmodule Track.BitmexClient do
  @moduledoc """
  A basic BitMEX Testnet API client using Req for paper trading operations.
  """
  alias Track.Exchanges
  alias Track.Exchanges.BitmexSetting
  alias Track.Accounts.Scope

  @base_url "https://testnet.bitmex.com"

  # Public API

  @doc """
  Fetches user's margin balance for a specific currency.
  """
  def get_balance(%Scope{} = scope, currency \\ "XBt") do
    settings = Exchanges.get_latest_bitmex_setting!(scope)
    request(settings, :get, "/api/v1/user/margin", %{}, %{"currency" => currency})
  end

  @doc """
  Places a market order for a given symbol, side, and quantity.
  """
  def place_market_order(%Scope{} = scope, symbol, side, quantity) when side in ["Buy", "Sell"] do
    settings = Exchanges.get_latest_bitmex_setting!(scope)

    body = %{
      "symbol" => symbol,
      "orderQty" => quantity,
      "side" => side,
      "ordType" => "Market"
    }

    request(settings, :post, "/api/v1/order", body)
  end

  @doc """
  Cancels all open orders for a given symbol (or all symbols if nil).
  """
  def cancel_all_orders(%Scope{} = scope, symbol \\ nil) do
    settings = Exchanges.get_latest_bitmex_setting!(scope)
    query = if symbol, do: %{"symbol" => symbol}, else: %{}
    request(settings, :delete, "/api/v1/order/all", %{}, query)
  end

  @doc """
  Fetches the order book for a given symbol and depth.
  """
  def get_order_book(%Scope{} = scope, symbol \\ "XBTUSD", depth \\ 1) do
    settings = Exchanges.get_latest_bitmex_setting!(scope)
    request(settings, :get, "/api/v1/orderBook/L2", %{}, %{"symbol" => symbol, "depth" => depth})
  end

  @doc """
  Fetches open positions for a given symbol (or all symbols if nil).
  The response includes unrealized and realized PnL for the position.
  """
  def get_positions(%Scope{} = scope, symbol \\ nil) do
    settings = Exchanges.get_latest_bitmex_setting!(scope)
    query = if symbol, do: %{"symbol" => symbol}, else: %{}
    request(settings, :get, "/api/v1/position", %{}, query)
  end

  @doc """
  Closes an open position for a given symbol by placing an opposing market order.
  """
  def close_position(%Scope{} = scope, symbol) do
    case get_positions(scope, symbol) do
      [%{"symbol" => ^symbol, "currentQty" => quantity} | _] when quantity != 0 ->
        side = if quantity > 0, do: "Sell", else: "Buy"
        place_market_order(scope, symbol, side, abs(quantity))

      _ ->
        {:error, "No open position found for #{symbol}"}
    end
  end

  @doc """
  Fetches recent trade executions for a given symbol.
  This data can be used to calculate realized PnL client-side if needed,
  though position data also includes realized PnL for the current position.
  """
  def get_trade_history(%Scope{} = scope, symbol \\ nil, opts \\ []) do
    settings = Exchanges.get_latest_bitmex_setting!(scope)
    query = Keyword.merge(opts, if(symbol, do: %{"symbol" => symbol}, else: %{}))
    request(settings, :get, "/api/v1/execution", %{}, query)
  end

  # Internal

  defp request(%BitmexSetting{} = bitmex_setting, method, path, body \\ %{}, query) do
    api_key = bitmex_setting.api_key
    api_secret = bitmex_setting.api_secret

    expires = :os.system_time(:second) + 60
    body_json = if method in [:post, :put], do: Jason.encode!(body), else: ""
    query_string = URI.encode_query(query)

    full_path =
      if query_string != "", do: "#{path}?#{query_string}", else: path

    signature = sign_request(api_secret, method, full_path, expires, body_json)

    headers = [
      {"api-key", api_key},
      {"api-expires", Integer.to_string(expires)},
      {"api-signature", signature},
      {"content-type", "application/json"}
    ]

    Req.request!(
      method: method,
      url: @base_url <> full_path,
      headers: headers,
      body: body_json
    )
    |> Map.get(:body)
    |> decode_result()
  end

  defp decode_result(body) when is_binary(body), do: Jason.decode!(body)
  defp decode_result(body), do: body

  defp sign_request(api_secret, verb, path, expires, body) do
    data = "#{verb |> to_string() |> String.upcase()}#{path}#{expires}#{body}"

    :crypto.mac(:hmac, :sha256, api_secret, data)
    |> Base.encode16(case: :lower)
  end
end
