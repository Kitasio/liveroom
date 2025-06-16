defmodule TrackWeb.RoomLive do
  alias Track.TradePnl.Trade
  alias Track.TradePnl
  use TrackWeb, :live_view
  import TrackWeb.RoomLive.Navbar
  import TrackWeb.RoomLive.TradingPanel
  import TrackWeb.RoomLive.Chart
  import TrackWeb.RoomLive.OrderLog
  alias Phoenix.PubSub

  def mount(%{"room_id" => room_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Track.PubSub, "room:#{room_id}")
      PubSub.subscribe(Track.PubSub, "btc_price")
      # PubSub.subscribe(Track.PubSub, "user:#{username}")
    end

    user_id = socket.assigns[:current_scope].user.id
    is_owner = user_id == parse_number(room_id)

    trade_state = %TradePnl.State{}

    {:ok,
     socket
     |> assign(:is_owner, is_owner)
     |> assign(:room_id, room_id)
     |> assign(:trade_state, trade_state)
     |> assign(:unrealized_pnl, 0)
     |> assign(:btc_price, 0.00)
     |> assign(:order_price, 1)
     |> assign(:user_balance, 100)}
  end

  def handle_event("buy", _params, socket) do
    user_balance = parse_number(socket.assigns[:user_balance])
    order_price = parse_number(socket.assigns[:order_price])
    new_balance = user_balance + order_price

    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:order_executed, :buy}
    )

    btc_price = parse_number(socket.assigns[:btc_price])

    trade_state =
      TradePnl.add_trade(socket.assigns[:trade_state], %Trade{
        side: :buy,
        amount_usd: order_price,
        price: btc_price
      })

    {:noreply,
     socket
     |> assign(:user_balance, new_balance)
     |> assign(:trade_state, trade_state)}
  end

  def handle_event("sell", _params, socket) do
    user_balance = parse_number(socket.assigns[:user_balance])
    order_price = parse_number(socket.assigns[:order_price])
    new_balance = user_balance - order_price

    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:order_executed, :sell}
    )

    btc_price = parse_number(socket.assigns[:btc_price])

    trade_state =
      TradePnl.add_trade(socket.assigns[:trade_state], %Trade{
        side: :sell,
        amount_usd: order_price,
        price: btc_price
      })

    {:noreply,
     socket
     |> assign(:user_balance, new_balance)
     |> assign(:trade_state, trade_state)}
  end

  def handle_event("update_user_balance", %{"user_balance" => user_balance}, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:price_or_balance_updated, socket.assigns[:order_price], user_balance}
    )

    {:noreply, socket |> assign(:user_balance, user_balance)}
  end

  def handle_event("update_order_price", %{"price" => price}, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:price_or_balance_updated, price, socket.assigns[:user_balance]}
    )

    {:noreply, socket |> assign(:order_price, price)}
  end

  def handle_info({:btc_price_updated, price}, socket) do
    btc_price = parse_number(price) |> Float.round(2)

    unrealized_pnl =
      TradePnl.unrealized_pnl(socket.assigns[:trade_state], btc_price) |> Float.round(2)

    {:noreply, assign(socket, btc_price: btc_price, unrealized_pnl: unrealized_pnl)}
  end

  def handle_info({:order_executed, :buy}, socket) do
    new_balance = socket.assigns[:user_balance] + socket.assigns[:order_price]
    {:noreply, socket |> assign(:user_balance, new_balance)}
  end

  def handle_info({:order_executed, :sell}, socket) do
    new_balance = socket.assigns[:user_balance] - socket.assigns[:order_price]
    {:noreply, socket |> assign(:user_balance, new_balance)}
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
      <.navbar is_owner={@is_owner} btc_price={@btc_price} unrealized_pnl={@unrealized_pnl} />
      
    <!-- Main Content Grid -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <.trading_panel is_owner={@is_owner} user_balance={@user_balance} order_price={@order_price} />
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
        Float.round(user_bal / init_bal * amt, 3)

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
