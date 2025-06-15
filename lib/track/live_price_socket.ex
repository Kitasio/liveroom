defmodule Track.LivePriceSocket do
  use WebSockex

  @ws_url "wss://stream.binance.com:9443/ws/btcusdt@ticker"

  def start_link(_opts) do
    WebSockex.start_link(@ws_url, __MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    with {:ok, data} <- Jason.decode(msg),
         %{"c" => price} <- data do
      Phoenix.PubSub.broadcast(Track.PubSub, "btc_price", {:btc_price_updated, price})
    end

    {:ok, state}
  end
end
