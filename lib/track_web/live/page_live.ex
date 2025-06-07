defmodule TrackWeb.PageLive do
  use TrackWeb, :live_view

  def mount(_params, _session, socket) do
    # Let's assume a fixed temperature for now
    temperature = 70
    {:ok, assign(socket, temperature: temperature, x: 0, y: 0)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def render(assigns) do
    IO.inspect(assigns)

    ~H"""
    <main id="screen" class="h-screen">
      <div id="dots"></div>
    </main>
    """
  end
end
