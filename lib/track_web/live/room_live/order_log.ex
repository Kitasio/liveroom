defmodule TrackWeb.RoomLive.OrderLog do
  use Phoenix.Component
  use TrackWeb, :live_view

  def order_log(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-primary">
          <.icon name="hero-clipboard-document-list" class="w-5 h-5" /> Positions
        </h2>
        <div class="divider my-2"></div>
        <div id="order-log" class="h-80 overflow-y-auto space-y-2">
          <div id="empty-order-log" class="only:block hidden text-center text-base-content/50 mt-8">
            <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-2 opacity-3" />
            <p class="text-sm">No open positions</p>
            <p class="text-xs opacity-70">Your open positions will appear here</p>
          </div>
          <div
            :for={position <- @positions}
            :if={position.is_open}
            class="border border-base-300 rounded-lg p-3 text-sm"
          >
            <p><strong>Quantity:</strong> {position.current_qty}</p>
            <p><strong>Leverage:</strong> {position.leverage}</p>
            <p>
              <strong>Unrealised PnL (USD):</strong> {position.unrealised_pnl_usd |> Decimal.round()}
            </p>
            <p>
              <strong>Realised PnL (USD):</strong> {position.realised_pnl_usd |> Decimal.round()}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
