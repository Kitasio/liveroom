defmodule TrackWeb.RoomLive.TradingPanel do
  use Phoenix.Component
  use TrackWeb, :live_view

  attr :is_owner, :boolean, required: true
  attr :user_balance, :integer, required: true
  attr :order_price, :integer, required: true

  def trading_panel(assigns) do
    ~H"""
    <!-- Trading Panel -->
    <div>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title text-primary">
            <.icon name="hero-currency-dollar" class="w-5 h-5" /> Trading Panel
          </h2>
          <!-- User Balance Section -->
          <div class="w-full">
            <div class="mt-2 p-3 bg-base-200 rounded-lg">
              <span class="text-sm opacity-70">Current Balance:</span>
              <span class="font-bold text-lg ml-2">
                $<span id="user_balance">{@user_balance}</span>
              </span>
            </div>
          </div>
        </div>
      </div>
      <!-- Order Amount -->
      <div class="form-control w-full mt-10">
        <label class="label">
          <span class="label-text font-semibold">Order Amount (USD)</span>
        </label>
        <form>
          <input
            id="price-input"
            min="1"
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
    """
  end
end
