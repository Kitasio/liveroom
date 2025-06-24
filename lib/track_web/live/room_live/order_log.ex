defmodule TrackWeb.RoomLive.OrderLog do
  use TrackWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :active_tab, :positions)}
  end

  @impl true
  def update(assigns, socket) do
    open_positions = Enum.filter(assigns.positions, &(&1.is_open && &1.current_qty != 0))

    socket =
      socket
      |> assign(assigns)
      |> assign(
        open_positions: open_positions,
        open_positions_count: Enum.count(open_positions),
        open_orders_count: Enum.count(assigns.open_orders)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("set_active_tab", %{"tab" => "positions"}, socket) do
    {:noreply, assign(socket, :active_tab, :positions)}
  end

  def handle_event("set_active_tab", %{"tab" => "orders"}, socket) do
    {:noreply, assign(socket, :active_tab, :orders)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl border border-base-300">
      <div class="card-body p-6">
        <div role="tablist" class="tabs tabs-lifted">
          <input
            type="radio"
            name="order_tabs"
            role="tab"
            class="tab"
            aria-label={"Open Positions (#{@open_positions_count})"}
            checked={@active_tab == :positions}
            phx-click="set_active_tab"
            phx-value-tab="positions"
            phx-target={@myself}
          />
          <div
            role="tabpanel"
            class="tab-content bg-base-100 border-base-300 rounded-box p-6 h-96 overflow-y-auto"
          >
            <div
              :if={@open_positions_count == 0}
              class="flex flex-col items-center justify-center h-full text-base-content/50"
            >
              <.icon name="hero-inbox" class="w-16 h-16 mb-4 opacity-30" />
              <p class="text-base font-medium mb-1">No open positions</p>
              <p class="text-sm opacity-70">Your active trades will appear here</p>
            </div>
            <div :if={@open_positions_count > 0} class="space-y-3">
              <.position_component :for={position <- @open_positions} position={position} />
            </div>
          </div>

          <input
            type="radio"
            name="order_tabs"
            role="tab"
            class="tab"
            aria-label={"Active Orders (#{@open_orders_count})"}
            checked={@active_tab == :orders}
            phx-click="set_active_tab"
            phx-value-tab="orders"
            phx-target={@myself}
          />
          <div
            role="tabpanel"
            class="tab-content bg-base-100 border-base-300 rounded-box p-6 h-96 overflow-y-auto"
          >
            <div
              :if={@open_orders_count == 0}
              class="flex flex-col items-center justify-center h-full text-base-content/50"
            >
              <.icon name="hero-inbox" class="w-16 h-16 mb-4 opacity-30" />
              <p class="text-base font-medium mb-1">No active orders</p>
              <p class="text-sm opacity-70">Your active orders will appear here</p>
            </div>
            <div :if={@open_orders_count > 0}>
              <.active_order_component :for={order <- @open_orders} order={order} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def position_component(assigns) do
    ~H"""
    <div class="card bg-base-50 border border-base-200 hover:border-base-300 transition-colors">
      <div class="card-body p-4">
        <div class="flex items-start justify-between">
          <div class="flex-1 space-y-2">
            <div class="flex items-center gap-3">
              <div class="flex items-center gap-2">
                <div class={[
                  "badge badge-sm font-medium",
                  if(@position.current_qty > 0, do: "badge-success", else: "badge-error")
                ]}>
                  {if @position.current_qty > 0, do: "LONG", else: "SHORT"}
                </div>
                <span class="font-mono text-sm font-semibold">
                  {abs(@position.current_qty)} USD
                </span>
              </div>
              <div class="badge badge-outline badge-xs">
                {@position.leverage}x
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3 text-xs">
              <div>
                <span class="text-base-content/60">Unrealized PnL</span>
                <div class={[
                  "font-mono font-semibold",
                  if(Decimal.compare(@position.unrealised_pnl_usd, 0) == :gt,
                    do: "text-success",
                    else: "text-error"
                  )
                ]}>
                  ${@position.unrealised_pnl_usd |> Decimal.round() |> Decimal.to_string()}
                </div>
              </div>
              <div>
                <span class="text-base-content/60">Realized PnL</span>
                <div class={[
                  "font-mono font-semibold",
                  if(Decimal.compare(@position.realised_pnl_usd, 0) == :gt,
                    do: "text-success",
                    else: "text-error"
                  )
                ]}>
                  ${@position.realised_pnl_usd |> Decimal.round() |> Decimal.to_string()}
                </div>
              </div>
            </div>
          </div>

          <div class="ml-4">
            <button
              phx-click="close_position"
              phx-value-symbol="XBTUSD"
              class="btn btn-sm btn-error btn-outline hover:btn-error"
              title="Close Position"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" /> Close
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def active_order_component(assigns) do
    ~H"""
    <div class="card bg-base-100 border border-base-200 mb-3">
      <div class="card-body p-4">
        <div class="flex justify-between items-center">
          <div class="flex items-center gap-3">
            <div class={[
              "badge",
              if(@order["side"] == "Buy", do: "badge-success", else: "badge-error")
            ]}>
              {@order["side"]}
            </div>
            <div class="font-mono">{@order["orderQty"]} USD</div>
            <div class="badge badge-outline badge-sm">{@order["ordType"]}</div>
          </div>
          <div>
            <button
              phx-click="cancel_order"
              phx-value-order_id={@order["orderID"]}
              class="btn btn-sm btn-ghost text-error"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>
        </div>
        <div class="mt-2 text-sm">
          <div :if={@order["price"]}>
            Price: <span class="font-mono">{@order["price"]}</span>
          </div>
          <div :if={@order["stopPx"]}>
            Stop Price: <span class="font-mono">{@order["stopPx"]}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
