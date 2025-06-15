defmodule TrackWeb.RoomLive do
  use TrackWeb, :live_view
  import TrackWeb.RoomLive.Navbar
  import TrackWeb.RoomLive.TradingPanel
  import TrackWeb.RoomLive.Chart
  import TrackWeb.RoomLive.OrderLog
  alias Phoenix.PubSub

  def mount(%{"room_id" => room_id}, %{"anon_user" => username}, socket) do
    if connected?(socket) do
      PubSub.subscribe(Track.PubSub, "room:#{room_id}")
      # PubSub.subscribe(Track.PubSub, "user:#{username}")
    end

    username = username |> String.split("_") |> Enum.join(" ")

    {:ok,
     socket
     |> assign(:username, username)
     |> assign(:room_id, room_id)
     |> assign(:order_price, 1)
     |> assign(:user_balance, 100)}
  end

  def handle_event("user_balance_updated", %{"user_balance" => user_balance}, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast!(
      Track.PubSub,
      topic,
      {:price_or_balance_updated, socket.assigns[:order_price], user_balance}
    )

    {:noreply, socket |> assign(:user_balance, user_balance)}
  end

  def handle_event("order_price_updated", %{"price" => price}, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast!(
      Track.PubSub,
      topic,
      {:price_or_balance_updated, price, socket.assigns[:user_balance]}
    )

    {:noreply, socket |> assign(:order_price, price)}
  end

  def handle_info({:price_or_balance_updated, price, initiator_balance}, socket) do
    user_balance = socket.assigns[:user_balance]

    propotional_price =
      calculate_proportional_amount(user_balance, initiator_balance, price)

    {:noreply, assign(socket, order_price: propotional_price)}
  end

  def render(assigns) do
    ~H"""
    <div id="screen" class="min-h-screen bg-base-200 p-4">
      <div id="dots"></div>
      
    <!-- Header Section -->
      <.navbar username={@username} />
      
    <!-- Main Content Grid -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <.trading_panel user_balance={@user_balance} order_price={@order_price} />
        <.chart />
        <.order_log />
      </div>
    </div>
    """
  end

  # Helper functions
  defp calculate_proportional_amount(user_user_balance, initiator_user_balance, amount) do
    case {parse_number(user_user_balance), parse_number(initiator_user_balance),
          parse_number(amount)} do
      {user_bal, init_bal, amt} when user_bal > 0 and init_bal > 0 and amt > 0 ->
        user_bal / init_bal * amt

      _ ->
        0
    end
  end

  defp parse_number(value) when is_binary(value) do
    case Float.parse(value) do
      {num, _} ->
        num

      :error ->
        case Integer.parse(value) do
          {num, _} -> num
          :error -> 0
        end
    end
  end

  defp parse_number(value) when is_number(value), do: value
  defp parse_number(_), do: 0
end
