defmodule TrackWeb.RoomLive do
  alias Track.Exchanges.BitmexState
  use TrackWeb, :live_view
  import TrackWeb.RoomLive.TradingPanel
  alias Phoenix.PubSub
  alias TrackWeb.Presence

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} wide={true}>
      <div id="screen" class="min-h-screen p-4">
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
            <.live_component
              module={TrackWeb.RoomLive.OrderLog}
              id="order-log"
              positions={@trade_state.positions}
              open_orders={@trade_state.open_orders}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    user_id = socket.assigns[:current_scope].user.id
    is_owner = Decimal.new(user_id) == parse_number(room_id)

    if connected?(socket) do
      PubSub.subscribe(Track.PubSub, "room:#{room_id}")
      PubSub.subscribe(Track.PubSub, "btc_price")
      :timer.send_interval(5_000, :tick)

      if is_owner do
        Presence.track_room(self(), room_id, %{})
      end

      send(self(), :tick)
    end

    {:ok,
     socket
     |> assign(:is_owner, is_owner)
     |> assign(:room_id, room_id)
     |> assign(:trade_state, BitmexState.new())
     |> assign(:btc_price, Decimal.new("0.00"))
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
    with %Decimal{} = btc_price_decimal <- parse_number(price) do
      btc_price = Decimal.round(btc_price_decimal, 2)
      {:noreply, assign(socket, btc_price: btc_price)}
    else
      _ -> {:noreply, socket}
    end
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
    new_socket_with_price = calculate_proportional_amount(socket, initiator_balance, price)
    proportional_price = ensure_multiple_of_100(new_socket_with_price)

    {:noreply, assign(socket, order_price: proportional_price)}
  end

  # Helper functions
  defp ensure_multiple_of_100(socket) do
    with %Decimal{} = order_price <- parse_number(socket.assigns.order_price) do
      hundred = Decimal.new(100)

      result =
        order_price
        |> Decimal.div(hundred)
        |> Decimal.round(0, :half_up)
        |> Decimal.mult(hundred)

      if Decimal.compare(result, 0) == :eq do
        hundred
      else
        result
      end
    else
      # Default to 100 if order_price is not a valid decimal.
      _ -> Decimal.new(100)
    end
  end

  defp place_order_and_update_balance(socket, side, order_params) do
    scope = socket.assigns[:current_scope]
    symbol = "XBTUSD"

    quantity_decimal = parse_number(socket.assigns[:order_price]) || Decimal.new(0)
    quantity = Decimal.to_integer(quantity_decimal)

    order_type = Map.get(order_params, :order_type, "Market")
    limit_price_decimal = Map.get(order_params, :limit_price)
    stop_loss_decimal = Map.get(order_params, :stop_loss)
    take_profit_decimal = Map.get(order_params, :take_profit)

    limit_price = if limit_price_decimal, do: Decimal.to_float(limit_price_decimal)
    stop_loss = if stop_loss_decimal, do: Decimal.to_float(stop_loss_decimal)
    take_profit = if take_profit_decimal, do: Decimal.to_float(take_profit_decimal)

    IO.inspect(
      %{
        side: side,
        order_type: order_type,
        quantity: quantity,
        limit_price: limit_price,
        stop_loss: stop_loss,
        take_profit: take_profit
      },
      label: "Placing Order"
    )

    if stop_loss || take_profit do
      opts = []
      opts = if stop_loss, do: Keyword.put(opts, :stop_loss, stop_loss), else: opts
      opts = if take_profit, do: Keyword.put(opts, :take_profit, take_profit), else: opts
      opts = Keyword.put(opts, :order_type, order_type)
      opts = if limit_price, do: Keyword.put(opts, :price, limit_price), else: opts

      Track.BitmexClient.place_order_with_sl_tp(scope, symbol, side, quantity, opts)
    else
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
    end

    send(self(), :tick)
  end

  defp calculate_proportional_amount(socket, initiator_user_balance, amount) do
    user_balance_usd = socket.assigns[:trade_state].balance.usd

    with %Decimal{} = user_bal <- parse_number(user_balance_usd),
         %Decimal{} = init_bal <- parse_number(initiator_user_balance),
         %Decimal{} = amt <- parse_number(amount),
         true <- Decimal.compare(user_bal, 0) == :gt,
         true <- Decimal.compare(init_bal, 0) == :gt,
         true <- Decimal.compare(amt, 0) == :gt do
      ratio = Decimal.div(user_bal, init_bal)
      order_price = Decimal.mult(ratio, amt) |> Decimal.round(3)

      assign(socket, order_price: order_price)
    else
      _ ->
        assign(socket, order_price: Decimal.new(0))
    end
  end

  defp parse_number(value) when is_binary(value) do
    if String.trim(value) == "" do
      nil
    else
      case Decimal.new(value) do
        %Decimal{} = decimal -> decimal
        _ -> nil
      end
    end
  end

  defp parse_number(value) when is_integer(value) or is_float(value), do: Decimal.new(value)
  defp parse_number(%Decimal{} = value), do: value
  defp parse_number(_), do: nil
end
