defmodule TrackWeb.RoomLive.Navbar do
  use Phoenix.Component
  use TrackWeb, :live_view

  attr :username, :string, required: true
  attr :btc_price, :string, required: true
  attr :unrealized_pnl, :integer, required: true

  def navbar(assigns) do
    ~H"""
    <div class="navbar bg-base-100 rounded-box shadow-lg mb-6">
      <div class="navbar-start">
        <div class="text-xl font-bold text-primary">
          <.icon name="hero-chart-bar" class="w-6 h-6 inline mr-2" /> Trading Dashboard
        </div>
      </div>
      <div class="navbar-center">
        <div class="stats shadow">
          <div class="stat">
            <div class="stat-title">Live BTC Price</div>
            <div class="stat-value text-2xl text-success" id="live-price">
              {@btc_price}
            </div>
          </div>
        </div>
      </div>
      <div class="navbar-end flex gap-5">
        <p :if={@unrealized_pnl != 0}>PNL: {@unrealized_pnl}</p>
        <p class="capitalize font-medium">{@username}</p>
      </div>
    </div>
    """
  end
end
