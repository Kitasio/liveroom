defmodule TrackWeb.PageLive do
  use TrackWeb, :live_view

  def mount(_params, %{"anon_user" => username}, socket) do
    username = username |> String.split("_") |> Enum.join(" ")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Track.PubSub, "order_log:#{username}")
    end

    {:ok,
     socket
     |> assign(:username, username)
     |> assign(:order_log, [])}
  end

  def handle_info({:order_log, entry}, socket) do
    order_log = [entry | socket.assigns[:order_log]]
    IO.inspect(order_log, label: "ORDER LOG")
    {:noreply, socket |> assign(:order_log, order_log)}
  end

  def render(assigns) do
    ~H"""
    <main id="screen" class="min-h-screen bg-base-200 p-4">
      <div id="dots"></div>
      
    <!-- Header Section -->
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
              <div class="stat-value text-2xl text-success" id="live-price" phx-hook="LivePrice">
                $0.00
              </div>
            </div>
          </div>
        </div>
        <div class="navbar-end">
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar placeholder">
              <div class="bg-neutral text-neutral-content rounded-full w-10">
                <span class="text-xs font-bold">{String.first(@username)}</span>
              </div>
            </div>
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
            >
              <li><a class="capitalize font-medium">{@username}</a></li>
            </ul>
          </div>
        </div>
      </div>
      
    <!-- Main Content Grid -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
    <!-- Trading Panel -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-primary">
              <.icon name="hero-currency-dollar" class="w-5 h-5" /> Trading Panel
            </h2>
            
    <!-- Balance Section -->
            <div class="form-control w-full">
              <label class="label">
                <span class="label-text font-semibold">Account Balance</span>
              </label>
              <div class="join">
                <input
                  id="balance-input"
                  placeholder="Enter balance"
                  class="input input-bordered join-item flex-1"
                  type="number"
                  value="100"
                />
                <div class="btn btn-outline join-item">USD</div>
              </div>
              <div class="mt-2 p-3 bg-base-200 rounded-lg">
                <span class="text-sm opacity-70">Current Balance:</span>
                <span class="font-bold text-lg ml-2">$<span id="balance">100</span></span>
              </div>
            </div>
            
    <!-- Order Amount -->
            <div class="form-control w-full mt-4">
              <label class="label">
                <span class="label-text font-semibold">Order Amount (USD)</span>
              </label>
              <input
                id="price-input"
                min="1"
                value="1"
                type="number"
                class="input input-bordered w-full"
                placeholder="Enter amount to trade"
              />
            </div>
            
    <!-- Trading Buttons -->
            <div class="card-actions justify-center mt-6">
              <div class="join w-full">
                <button id="buy-btn" class="btn btn-success join-item flex-1">
                  <.icon name="hero-arrow-trending-up" class="w-4 h-4" /> Buy BTC
                </button>
                <button id="sell-btn" class="btn btn-error join-item flex-1">
                  <.icon name="hero-arrow-trending-down" class="w-4 h-4" /> Sell BTC
                </button>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Chart Section -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-primary">
              <.icon name="hero-chart-bar-square" class="w-5 h-5" /> Price Chart
            </h2>
            <div id="chart" phx-hook="CandleChart" class="w-full h-80 bg-base-50 rounded-lg" />
          </div>
        </div>
        
    <!-- Order Log Section -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-primary">
              <.icon name="hero-clipboard-document-list" class="w-5 h-5" /> Order History
            </h2>
            <div class="divider my-2"></div>
            <div id="order-log" class="h-80 overflow-y-auto space-y-2">
              <div :for={entry <- @order_log} id={"entry-#{entry.id}"}>
                <span class="text-xs text-gray-500">{format_time(entry.timestamp)}</span>
                <span class={action_class(entry.action) <> " font-semibold"}>
                  {entry.action}
                </span>
                <span>${entry.amount}</span>
                <span class="text-xs">@ ${entry.btc_price}</span>
                <span class="text-xs">by {entry.username}</span>
              </div>
              <div
                id="empty-order-log"
                class="only:block hidden text-center text-base-content/50 mt-8"
              >
                <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-2 opacity-30" />
                <p class="text-sm">No orders yet</p>
                <p class="text-xs opacity-70">Your trading history will appear here</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Footer Stats -->
      <div class="mt-6">
        <div class="stats stats-vertical lg:stats-horizontal shadow w-full bg-base-100">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-users" class="w-8 h-8" />
            </div>
            <div class="stat-title">Active Traders</div>
            <div class="stat-value text-primary">Online</div>
            <div class="stat-desc">Real-time collaboration</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-secondary">
              <.icon name="hero-arrow-path" class="w-8 h-8" />
            </div>
            <div class="stat-title">Market Status</div>
            <div class="stat-value text-secondary">Live</div>
            <div class="stat-desc">24/7 trading</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-accent">
              <.icon name="hero-signal" class="w-8 h-8" />
            </div>
            <div class="stat-title">Connection</div>
            <div class="stat-value text-accent">Stable</div>
            <div class="stat-desc">Real-time updates</div>
          </div>
        </div>
      </div>
    </main>
    """
  end

  defp format_time(ts) do
    ts |> DateTime.from_iso8601() |> elem(1) |> Calendar.strftime("%H:%M:%S")
  end

  defp action_class("BUY"), do: "text-green-600"
  defp action_class("SELL"), do: "text-red-600"
  defp action_class(_), do: "text-gray-600"
end
