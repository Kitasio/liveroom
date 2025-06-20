defmodule TrackWeb.RoomLive.TradingPanel do
  use Phoenix.Component
  use TrackWeb, :live_view

  attr :is_owner, :boolean, required: true
  attr :balance_btc, :integer, required: true
  attr :balance_usd, :integer, required: true
  attr :order_price, :integer, required: true
  attr :btc_live_price, :integer, required: true

  def trading_panel(assigns) do
    ~H"""
    <!-- Trading Panel -->
    <div>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="card-title text-primary flex justify-between">
            <h2>
              <.icon name="hero-currency-dollar" class="w-5 h-5" /> Trading Panel
            </h2>
            <div class="flex items-center justify-center gap-2">
              <img class="w-4 h-4 inline" src="/images/btc.svg" />
              <p class="text-sm">{:erlang.float_to_binary(@btc_live_price, decimals: 2)}</p>
            </div>
          </div>
          <!-- User Balance Section -->
          <div class="stats bg-base-100 border-base-300 border">
            <div class="stat">
              <div class="stat-title">Balance USD</div>
              <div class="stat-value">${@balance_usd}</div>
            </div>

            <div class="stat relative">
              <div class="stat-title">Balance BTC</div>
              <div class="stat-value">{@balance_btc}</div>
            </div>
          </div>
          <!-- Order Amount -->
          <div class="form-control w-full mt-10">
            <label class="label">
              <span class="label-text font-semibold">Order Amount (USD)</span>
            </label>
            <form>
              <input
                type="range"
                min="0"
                max="10000"
                value={@order_price}
                class="range w-full my-3"
                step="100"
                id="price-range"
                name="price-range"
                phx-input="update_order_price"
                phx-change="update_order_price"
              />
              <input
                id="price-input"
                min="0"
                step="100"
                name="price"
                value={@order_price}
                type="number"
                class="input input-bordered w-full"
                placeholder="Enter amount to trade"
                phx-change="update_order_price"
                disabled={!@is_owner}
              />
            </form>
          </div>
          <!-- Trading Buttons -->
          <div class="card-actions justify-center mt-6">
            <div class="join w-full">
              <button phx-click="buy" id="buy-btn" class="btn btn-success join-item flex-1">
                <.icon name="hero-arrow-trending-up" class="w-4 h-4" /> Buy BTC
              </button>
              <button phx-click="sell" id="sell-btn" class="btn btn-error join-item flex-1">
                <.icon name="hero-arrow-trending-down" class="w-4 h-4" /> Sell BTC
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
