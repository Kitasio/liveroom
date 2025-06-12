defmodule TrackWeb.PageLive do
  use TrackWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, x: 0, y: 0)}
  end

  def render(assigns) do
    IO.inspect(assigns)

    ~H"""
    <main id="screen" class="h-screen">
      <div id="dots"></div>
      <input id="price-input" type="number" class="rounded border m-5" />

      <div id="chart" phx-hook="CandleChart" />
      <div>BTC Price: <span id="live-price" phx-hook="LivePrice">$0.00</span></div>
    </main>
    """
  end
end
