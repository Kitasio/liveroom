defmodule TrackWeb.RoomLive.OrderLog do
  use Phoenix.Component
  use TrackWeb, :live_view

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

  def order_log(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl border border-base-300">
      <div class="card-body p-6">
        <div class="flex items-center justify-between mb-4">
          <h2 class="card-title text-primary text-lg font-semibold">
            <.icon name="hero-chart-bar" class="w-5 h-5" /> Open Positions
          </h2>
        </div>

        <div class="divider my-0"></div>

        <div id="order-log" class="h-80 overflow-y-auto">
          <div
            id="empty-order-log"
            class="only:flex hidden flex-col items-center justify-center h-full text-base-content/50"
          >
            <.icon name="hero-inbox" class="w-16 h-16 mb-4 opacity-30" />
            <p class="text-base font-medium mb-1">No open positions</p>
            <p class="text-sm opacity-70">Your active trades will appear here</p>
          </div>

          <div class="space-y-3">
            <.position_component
              :for={position <- @positions}
              :if={position.is_open && position.current_qty != 0}
              position={position}
            />
          </div>
        </div>

        <div class="mt-6">
          <h3 class="card-title text-primary text-lg font-semibold mb-4">
            <.icon name="hero-document-text" class="w-5 h-5" /> Active Orders
          </h3>
          <div class="divider my-0"></div>
          <div class="mt-4">
            <div :if={Enum.empty?(@open_orders)} class="text-center py-8 text-base-content/50">
              <.icon name="hero-inbox" class="w-12 h-12 mx-auto opacity-30" />
              <p class="mt-2 font-medium">No active orders</p>
            </div>
            <.active_order_component :for={order <- @open_orders} order={order} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
