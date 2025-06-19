defmodule TrackWeb.RoomLive do
  alias Track.UserTradeState
  use TrackWeb, :live_view
  import TrackWeb.RoomLive.Navbar
  import TrackWeb.RoomLive.TradingPanel
  import TrackWeb.RoomLive.Chart
  import TrackWeb.RoomLive.OrderLog
  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    <div id="screen" class="min-h-screen bg-base-200 p-4">
      <div id="dots"></div>
      <!-- Header Section -->
      <.navbar
        is_owner={@is_owner}
        btc_price={@btc_price}
        unrealised_pnl={@trade_state.unrealised_pnl}
        position_open={@trade_state.position_open}
      />
      <!-- Main Content Grid -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <.trading_panel
          is_owner={@is_owner}
          user_balance={@trade_state.balance_usd}
          order_price={@order_price}
        />
        <.chart />
        <.order_log />
      </div>
    </div>
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Track.PubSub, "room:#{room_id}")
      PubSub.subscribe(Track.PubSub, "btc_price")
      :timer.send_interval(5_000, :tick)

      send(self(), :load_balance)
      send(self(), :tick)
    end

    user_id = socket.assigns[:current_scope].user.id
    is_owner = user_id == parse_number(room_id)

    {:ok,
     socket
     |> assign(:is_owner, is_owner)
     |> assign(:room_id, room_id)
     |> assign(:trade_state, UserTradeState.new())
     |> assign(:btc_price, 0.00)
     |> assign(:order_price, 1)}
  end

  def handle_event("buy", _params, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:order_executed, :buy}
    )

    place_order_and_update_balance(socket, "Buy")

    {:noreply, socket}
  end

  def handle_event("sell", _params, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:order_executed, :sell}
    )

    place_order_and_update_balance(socket, "Sell")

    {:noreply, socket}
  end

  def handle_event("update_order_price", %{"price" => price}, socket) do
    topic = "room:#{socket.assigns[:room_id]}"
    balance_usd = UserTradeState.get_balance(socket.assigns[:trade_state], :usd)

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:price_or_balance_updated, price, balance_usd}
    )

    {:noreply, socket |> assign(:order_price, price)}
  end

  def handle_info(:tick, socket) do
    position = Track.BitmexClient.get_positions(socket.assigns[:current_scope], "XBTUSD") |> hd()

    new_trade_state =
      UserTradeState.update_position(
        socket.assigns[:trade_state],
        position,
        socket.assigns[:btc_price]
      )

    {:noreply, assign(socket, :trade_state, new_trade_state)}
  end

  def handle_info(:load_balance, socket) do
    scope = socket.assigns[:current_scope]
    %{"amount" => balance} = Track.BitmexClient.get_balance(scope) |> hd()

    new_trade_state =
      UserTradeState.update_balance(socket.assigns[:trade_state], {:sats, balance})

    {:noreply, assign(socket, :trade_state, new_trade_state)}
  end

  def handle_info({:btc_price_updated, price}, socket) do
    btc_price = parse_number(price) |> Float.round(2)

    new_trade_state =
      UserTradeState.update_balance(
        socket.assigns[:trade_state],
        {:sats, socket.assigns[:trade_state].balance_sats},
        btc_price
      )

    {:noreply, assign(socket, trade_state: new_trade_state, btc_price: btc_price)}
  end

  def handle_info({:order_executed, :buy}, socket) do
    place_order_and_update_balance(socket, "Buy")
    {:noreply, socket}
  end

  def handle_info({:order_executed, :sell}, socket) do
    place_order_and_update_balance(socket, "Sell")
    {:noreply, socket}
  end

  def handle_info({:price_or_balance_updated, price, initiator_balance}, socket) do
    propotional_price =
      socket
      |> calculate_proportional_amount(initiator_balance, price)
      |> ensure_multiple_of_100()

    {:noreply, assign(socket, order_price: propotional_price)}
  end

  # Helper functions
  defp ensure_multiple_of_100(socket) do
    order_price = parse_number(socket.assigns[:order_price])

    case round(order_price / 100) * 100 do
      0 -> 100
      price -> price
    end
  end

  defp place_order_and_update_balance(socket, side) do
    Track.BitmexClient.place_market_order(
      socket.assigns[:current_scope],
      "XBTUSD",
      side,
      parse_number(socket.assigns[:order_price])
    )

    send(self(), :load_balance)
  end

  defp calculate_proportional_amount(socket, initiator_user_balance, amount) do
    user_balance_usd = UserTradeState.get_balance(socket.assigns[:trade_state], :usd)

    case {parse_number(user_balance_usd), parse_number(initiator_user_balance),
          parse_number(amount)} do
      {user_bal, init_bal, amt} when user_bal > 0 and init_bal > 0 and amt > 0 ->
        order_price = Float.round(user_bal / init_bal * amt, 3)
        assign(socket, order_price: order_price)

      _ ->
        assign(socket, order_price: 0)
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
