defmodule Track.BitmexClient do
  @moduledoc """
  A basic BitMEX Testnet API client using Req for paper trading operations.
  """

  @base_url "https://testnet.bitmex.com"
  @api_key System.get_env("BITMEX_TESTNET_ID")
  @api_secret System.get_env("BITMEX_TESTNET_KEY")

  # Public API

  @doc """
  Fetches user's margin balance for a specific currency.
  """
  def get_balance(currency \\ "XBt") do
    request(:get, "/api/v1/user/margin", %{}, %{"currency" => currency})
  end

  @doc """
  Places a market order for a given symbol, side, and quantity.
  """
  def place_market_order(symbol, side, quantity) when side in ["Buy", "Sell"] do
    body = %{
      "symbol" => symbol,
      "orderQty" => quantity,
      "side" => side,
      "ordType" => "Market"
    }

    request(:post, "/api/v1/order", body)
  end

  @doc """
  Cancels all open orders for a given symbol (or all symbols if nil).
  """
  def cancel_all_orders(symbol \\ nil) do
    query = if symbol, do: %{"symbol" => symbol}, else: %{}
    request(:delete, "/api/v1/order/all", %{}, query)
  end

  @doc """
  Fetches the order book for a given symbol and depth.
  """
  def get_order_book(symbol \\ "XBTUSD", depth \\ 1) do
    request(:get, "/api/v1/orderBook/L2", %{}, %{"symbol" => symbol, "depth" => depth})
  end

  @doc """
  Fetches open positions for a given symbol (or all symbols if nil).
  The response includes unrealized and realized PnL for the position.
  """
  def get_positions(symbol \\ nil) do
    query = if symbol, do: %{"symbol" => symbol}, else: %{}
    request(:get, "/api/v1/position", %{}, query)
  end

  @doc """
  Closes an open position for a given symbol by placing an opposing market order.
  """
  def close_position(symbol) do
    case get_positions(symbol) do
      [%{"symbol" => ^symbol, "currentQty" => quantity} | _] when quantity != 0 ->
        side = if quantity > 0, do: "Sell", else: "Buy"
        place_market_order(symbol, side, abs(quantity))

      _ ->
        {:error, "No open position found for #{symbol}"}
    end
  end

  @doc """
  Fetches recent trade executions for a given symbol.
  This data can be used to calculate realized PnL client-side if needed,
  though position data also includes realized PnL for the current position.
  """
  def get_trade_history(symbol \\ nil, opts \\ []) do
    query = Keyword.merge(opts, if(symbol, do: %{"symbol" => symbol}, else: %{}))
    request(:get, "/api/v1/execution", %{}, query)
  end

  # Internal

  defp request(method, path, body \\ %{}, query) do
    expires = :os.system_time(:second) + 60
    body_json = if method in [:post, :put], do: Jason.encode!(body), else: ""
    query_string = URI.encode_query(query)

    full_path =
      if query_string != "", do: "#{path}?#{query_string}", else: path

    signature = sign_request(method, full_path, expires, body_json)

    headers = [
      {"api-key", @api_key},
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

  defp sign_request(verb, path, expires, body) do
    data = "#{verb |> to_string() |> String.upcase()}#{path}#{expires}#{body}"

    :crypto.mac(:hmac, :sha256, @api_secret, data)
    |> Base.encode16(case: :lower)
  end
end
