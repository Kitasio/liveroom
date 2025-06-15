defmodule TrackWeb.RoomLive.Chart do
  use Phoenix.Component
  use TrackWeb, :live_view

  def chart(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-primary">
          <.icon name="hero-chart-bar-square" class="w-5 h-5" /> Price Chart
        </h2>
        <div id="chart" phx-hook="CandleChart" class="w-full h-80 bg-base-50 rounded-lg" />
      </div>
    </div>
    """
  end
end
