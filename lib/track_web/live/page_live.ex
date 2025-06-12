defmodule TrackWeb.PageLive do
  use TrackWeb, :live_view

  def mount(_params, %{"anon_user" => username}, socket) do
    username = username |> String.split("_") |> Enum.join(" ")
    {:ok, assign(socket, username: username)}
  end

  def render(assigns) do
    ~H"""
    <main id="screen" class="h-screen">
      <div id="dots"></div>
      <p id="username" class="capitalize">{@username}</p>
      <input id="balance-input" placeholder="balance" class="input" />
      <p>Balance: <span id="balance">0</span></p>

      <div class="flex flex-col lg:flex-row">
        <div>
          <div>BTC Price: <span id="live-price" phx-hook="LivePrice">$0.00</span></div>
          <input id="price-input" min="1" value="1" type="number" class="input" />
          <div class="flex gap-5">
            <button id="buy-btn" class="btn btn-primary">Buy</button>
            <button id="sell-btn" class="btn btn-secondary">Sell</button>
          </div>
        </div>
        <div id="chart" phx-hook="CandleChart" class="w-full" />
      </div>
    </main>
    """
  end
end
