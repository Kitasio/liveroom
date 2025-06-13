defmodule TrackWeb.PriceLive do
  use TrackWeb, :live_view
  alias Phoenix.PubSub

  @topic "shared_price"

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(Track.PubSub, @topic)

    {:ok, assign(socket, price: "")}
  end

  def render(assigns) do
    ~H"""
    <div class="p-4 max-w-md mx-auto">
      <h1 class="text-xl mb-2">Shared Price Input</h1>
      <form phx-change="price_changed">
        <input
          type="text"
          name="price"
          value={@price}
          class="border p-2 rounded w-full"
          placeholder="Enter price"
        />
      </form>
      <p class="mt-4 text-gray-600">Current shared price: <strong>{@price}</strong></p>
    </div>
    """
  end

  def handle_event("price_changed", %{"price" => price}, socket) do
    PubSub.broadcast(Track.PubSub, @topic, {:price_updated, price})
    {:noreply, assign(socket, price: price)}
  end

  def handle_info({:price_updated, price}, socket) do
    {:noreply, assign(socket, price: price)}
  end
end
