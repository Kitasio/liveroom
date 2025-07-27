defmodule Track.Exchanges.BitmexClient.OrderTest do
  use Track.DataCase, async: true

  alias Track.Exchanges.BitmexClient.Order

  describe "from_map/1" do
    test "correctly maps order data" do
      order_map = %{
        "orderID" => "some-uuid",
        "symbol" => "XBTUSD",
        "side" => "Buy",
        "orderQty" => 100,
        "price" => 50_000.5,
        "ordType" => "Market",
        "ordStatus" => "Filled",
        "text" => "Order filled"
      }

      expected_order = %Order{
        order_id: "some-uuid",
        symbol: "XBTUSD",
        side: "Buy",
        order_qty: 100,
        price: 50_000.5,
        ord_type: "Market",
        ord_status: "Filled",
        text: "Order filled"
      }

      assert Order.from_map(order_map) == expected_order
    end
  end
end
