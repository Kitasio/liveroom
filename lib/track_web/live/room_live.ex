defmodule TrackWeb.RoomLive do
  alias Track.Exchanges.BitmexState
  use TrackWeb, :live_view
  import TrackWeb.RoomLive.TradingPanel
  import TrackWeb.RoomLive.OrderLog
  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    <div id="screen" class="min-h-screen bg-base-200 p-4">
      <div id="dots"></div>
      <!-- Main Content Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        <.trading_panel
          is_owner={@is_owner}
          order_price={@order_price}
          btc_live_price={@btc_price}
          trade_state={@trade_state}
          order_type={@order_type}
          position_action={@position_action}
          limit_price={@limit_price}
          stop_loss={@stop_loss}
          take_profit={@take_profit}
        />
        <div class="xl:col-span-2">
          <.order_log positions={@trade_state.positions} open_orders={@trade_state.open_orders} />
        </div>
      </div>
    </div>
    <Layouts.flash_group flash={@flash} />
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Track.PubSub, "room:#{room_id}")
      PubSub.subscribe(Track.PubSub, "btc_price")
      :timer.send_interval(5_000, :tick)

      send(self(), :tick)
    end

    user_id = socket.assigns[:current_scope].user.id
    is_owner = user_id == parse_number(room_id)

    {:ok,
     socket
     |> assign(:is_owner, is_owner)
     |> assign(:room_id, room_id)
     |> assign(:trade_state, BitmexState.new())
     |> assign(:btc_price, 0.00)
     |> assign(:order_price, nil)
     |> assign(:order_type, "Market")
     |> assign(:position_action, "Open")
     |> assign(:limit_price, nil)
     |> assign(:stop_loss, nil)
     |> assign(:take_profit, nil)}
  end

  def handle_event("buy", _params, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast!(
      Track.PubSub,
      topic,
      {:order_executed, :buy, socket.assigns}
    )

    {:noreply, socket}
  end

  def handle_event("sell", _params, socket) do
    topic = "room:#{socket.assigns[:room_id]}"

    PubSub.broadcast!(
      Track.PubSub,
      topic,
      {:order_executed, :sell, socket.assigns}
    )

    {:noreply, socket}
  end

  def handle_event("update_order_type", %{"value" => order_type}, socket) do
    {:noreply, assign(socket, :order_type, order_type)}
  end

  def handle_event("update_position_action", %{"value" => position_action}, socket) do
    {:noreply, assign(socket, :position_action, position_action)}
  end

  def handle_event("update_limit_price", %{"limit_price" => limit_price}, socket) do
    {:noreply, assign(socket, :limit_price, parse_number(limit_price))}
  end

  def handle_event("update_stop_loss", %{"stop_loss" => stop_loss}, socket) do
    {:noreply, assign(socket, :stop_loss, parse_number(stop_loss))}
  end

  def handle_event("update_take_profit", %{"take_profit" => take_profit}, socket) do
    {:noreply, assign(socket, :take_profit, parse_number(take_profit))}
  end

  def handle_event("update_order_price", params, socket) do
    price = Map.get(params, "price") || Map.get(params, "price-range")
    topic = "room:#{socket.assigns[:room_id]}"
    balance_usd = socket.assigns[:trade_state].balance.usd

    PubSub.broadcast_from!(
      Track.PubSub,
      self(),
      topic,
      {:price_or_balance_updated, price, balance_usd}
    )

    {:noreply, socket |> assign(:order_price, price)}
  end

  def handle_event("close_position", %{"symbol" => symbol}, socket) do
    case Track.BitmexClient.close_position(socket.assigns[:current_scope], symbol) do
      {:error, reason} ->
        # You could add a flash message here if needed
        IO.puts("Failed to close position: #{reason}")
        {:noreply, socket}

      _result ->
        # Refresh the trade state after closing position
        send(self(), :tick)
        {:noreply, socket}
    end
  end

  def handle_event("cancel_order", %{"order_id" => order_id}, socket) do
    case Track.BitmexClient.cancel_order(socket.assigns[:current_scope], order_id) do
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel order: #{reason}")}

      _ ->
        send(self(), :tick)
        {:noreply, put_flash(socket, :info, "Order canceled")}
    end
  end

  def handle_info(:tick, socket) do
    updated_trade_state =
      Track.Exchanges.get_bitmex_state(socket.assigns[:current_scope])

    {:noreply,
     socket
     |> assign(:trade_state, updated_trade_state)}
  end

  def handle_info({:btc_price_updated, price}, socket) do
    btc_price = parse_number(price) |> Float.round(2)
    {:noreply, assign(socket, btc_price: btc_price)}
  end

  def handle_info({:order_executed, :buy, order_params}, socket) do
    place_order_and_update_balance(socket, "Buy", order_params)

    {:noreply,
     socket
     |> put_flash(:info, "Executed BUY order")}
  end

  def handle_info({:order_executed, :sell, order_params}, socket) do
    place_order_and_update_balance(socket, "Sell", order_params)

    {:noreply,
     socket
     |> put_flash(:info, "Executed SELL order")}
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

  defp place_order_and_update_balance(socket, side, order_params) do
    scope = socket.assigns[:current_scope]
    symbol = "XBTUSD"
    quantity = parse_number(socket.assigns[:order_price])

    order_type = Map.get(order_params, :order_type, "Market")
    limit_price = Map.get(order_params, :limit_price)
    stop_loss = Map.get(order_params, :stop_loss)
    take_profit = Map.get(order_params, :take_profit)

    result =
      case order_type do
        "Market" ->
          Track.BitmexClient.place_market_order(scope, symbol, side, quantity)

        "Limit" when is_number(limit_price) ->
          Track.BitmexClient.place_limit_order(scope, symbol, side, quantity, limit_price)

        "Stop Market" when is_number(limit_price) ->
          Track.BitmexClient.place_stop_market_order(scope, symbol, side, quantity, limit_price)

        _ ->
          Track.BitmexClient.place_market_order(scope, symbol, side, quantity)
      end

    # Handle stop loss and take profit if specified
    if (stop_loss || take_profit) && match?({:ok, _}, result) do
      opts = []
      opts = if stop_loss, do: Keyword.put(opts, :stop_loss, stop_loss), else: opts
      opts = if take_profit, do: Keyword.put(opts, :take_profit, take_profit), else: opts

      if opts != [] do
        Track.BitmexClient.place_order_with_sl_tp(scope, symbol, side, quantity, opts)
      end
    end

    send(self(), :tick)
  end

  defp calculate_proportional_amount(socket, initiator_user_balance, amount) do
    user_balance_usd = socket.assigns[:trade_state].balance.usd

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
