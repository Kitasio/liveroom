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
            <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-2 opacity-30" />
            <p class="text-sm">No orders yet</p>
            <p class="text-xs opacity-70">Your positions will appear here</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
