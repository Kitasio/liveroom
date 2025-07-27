defmodule Track.Exchanges.BitmexClient.Order do
  alias Track.Accounts.Scope
  alias Track.Exchanges.BitmexClient.API

  defstruct [
    :order_id,
    :symbol,
    :side,
    :order_qty,
    :price,
    :ord_type,
    :ord_status,
    :text
  ]

  @type t :: %__MODULE__{}

  def from_map(order_map) when is_map(order_map) do
    %__MODULE__{
      order_id: Map.get(order_map, "orderID"),
      symbol: Map.get(order_map, "symbol"),
      side: Map.get(order_map, "side"),
      order_qty: Map.get(order_map, "orderQty"),
      price: Map.get(order_map, "price"),
      ord_type: Map.get(order_map, "ordType"),
      ord_status: Map.get(order_map, "ordStatus"),
      text: Map.get(order_map, "text")
    }
  end

  @doc """
  Places a market order for a given symbol, side, and quantity.

  ## Examples

      iex> Track.Exchanges.BitmexClient.Order.place_market_order(scope, "XBTUSD", "Buy", 100)
      {:ok, order_details}
  """
  def place_market_order(%Scope{} = scope, symbol, side, quantity) when side in ["Buy", "Sell"] do
    case API.place_market_order(scope, symbol, side, quantity) do
      {:ok, order_details} ->
        {:ok, from_map(order_details)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
