defmodule TrackWeb.RoomLive do
  use TrackWeb, :live_view
  import TrackWeb.RoomLive.Navbar
  import TrackWeb.RoomLive.TradingPanel
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
     |> assign(:price_input_value, 1)
     |> assign(:balance, 100)}
  end

  def handle_event("balance-change", %{"balance" => balance}, socket) do
    {:noreply, socket |> assign(:balance, balance)}
  end

  def handle_event("price-input-change", %{"price" => price}, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast!(
      Track.PubSub,
      topic,
      {:price_input_updated, price, socket.assigns[:balance]}
    )

    {:noreply, socket |> assign(:price_input_value, price)}
  end

  def handle_info({:price_input_updated, price, initiator_balance}, socket) do
    user_balance = socket.assigns[:balance]
    propotional_price = calculate_proportional_amount(user_balance, initiator_balance, price)
    {:noreply, assign(socket, price_input_value: propotional_price)}
  end

  def render(assigns) do
    ~H"""
    <div id="screen" class="min-h-screen bg-base-200 p-4">
      <div id="dots"></div>
      
    <!-- Header Section -->
      <.navbar username={@username} />
      
    <!-- Main Content Grid -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <.trading_panel balance={@balance} price_input_value={@price_input_value} />
      </div>
    </div>
    """
  end

  defp calculate_proportional_amount(user_balance, initiator_balance, amount) do
    case {parse_number(user_balance), parse_number(initiator_balance), parse_number(amount)} do
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
