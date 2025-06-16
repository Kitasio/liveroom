defmodule Track.BitmexClient do
  @moduledoc """
  A basic BitMEX Testnet API client using Req for paper trading operations.
  """

  @base_url "https://testnet.bitmex.com"
  @api_key System.get_env("BITMEX_TESTNET_ID")
  @api_secret System.get_env("BITMEX_TESTNET_KEY")

  # Public API

  def get_balance do
    request(:get, "/api/v1/user/margin", %{}, %{"currency" => "XBt"})
  end

  def place_market_order(symbol, side, quantity) when side in ["Buy", "Sell"] do
    body = %{
      "symbol" => symbol,
      "orderQty" => quantity,
      "side" => side,
      "ordType" => "Market"
    }

    request(:post, "/api/v1/order", body)
  end

  def cancel_all_orders(symbol \\ nil) do
    query = if symbol, do: %{"symbol" => symbol}, else: %{}
    request(:delete, "/api/v1/order/all", %{}, query)
  end

  def get_order_book(symbol \\ "XBTUSD", depth \\ 1) do
    request(:get, "/api/v1/orderBook/L2", %{}, %{"symbol" => symbol, "depth" => depth})
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
