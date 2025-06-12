defmodule TrackWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, assign(socket, user_balance: 100, username: get_username(socket))}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("mouse_move", %{"x" => x, "y" => y} = params, socket) do
    hash = Map.get(params, "id", :erlang.phash2(socket.channel_pid))
    color = Map.get(params, "color", random_color(hash))

    broadcast!(socket, "mouse_move", %{
      "x" => x,
      "y" => y,
      "id" => hash,
      "color" => color
    })

    {:noreply, socket}
  end

  def handle_in("price_input_change", %{"value" => value, "balance" => balance}, socket) do
    broadcast!(socket, "price_input_change", %{"value" => value, "balance" => balance})
    {:noreply, socket}
  end

  def handle_in("balance_input_change", %{"balance" => balance}, socket) do
    push(socket, "balance_input_change", %{balance: balance})
    {:noreply, assign(socket, user_balance: balance)}
  end

  def handle_in(
        "buy_order",
        %{"amount" => amount, "balance" => balance, "btc_price" => btc_price},
        socket
      ) do
    username = socket.assigns[:username]
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    broadcast!(socket, "order_log", %{
      "timestamp" => timestamp,
      "action" => "BUY",
      "amount" => amount,
      "username" => username,
      "btc_price" => btc_price,
      "initiator_balance" => balance
    })

    broadcast!(socket, "buy_order", %{"amount" => amount, "balance" => balance})
    {:noreply, socket}
  end

  def handle_in(
        "sell_order",
        %{"amount" => amount, "balance" => balance, "btc_price" => btc_price},
        socket
      ) do
    username = socket.assigns[:username]
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    broadcast!(socket, "order_log", %{
      "timestamp" => timestamp,
      "action" => "SELL",
      "amount" => amount,
      "username" => username,
      "btc_price" => btc_price,
      "initiator_balance" => balance
    })

    broadcast!(socket, "sell_order", %{"amount" => amount, "balance" => balance})
    {:noreply, socket}
  end

  intercept ["price_input_change", "buy_order", "sell_order", "order_log"]

  def handle_out("price_input_change", %{"value" => value, "balance" => balance}, socket) do
    user_balance = socket.assigns[:user_balance]
    IO.inspect(user_balance, label: "HANDLE OUT USER BALANCE")

    user_value =
      String.to_integer(user_balance) / String.to_integer(balance) * String.to_integer(value)

    push(socket, "price_input_change", %{"value" => user_value, "balance" => balance})
    {:noreply, socket}
  end

  def handle_out("buy_order", %{"amount" => amount, "balance" => balance}, socket) do
    user_balance = socket.assigns[:user_balance]

    # Calculate user's proportional dollar amount based on their balance
    user_dollar_amount = calculate_proportional_amount(user_balance, balance, amount)

    push(socket, "price_input_change", %{"value" => user_dollar_amount, "balance" => balance})
    {:noreply, socket}
  end

  def handle_out("sell_order", %{"amount" => amount, "balance" => balance}, socket) do
    user_balance = socket.assigns[:user_balance]

    # Calculate user's proportional dollar amount based on their balance
    user_dollar_amount = calculate_proportional_amount(user_balance, balance, amount)

    push(socket, "price_input_change", %{"value" => user_dollar_amount, "balance" => balance})
    {:noreply, socket}
  end

  def handle_out(
        "order_log",
        %{
          "timestamp" => timestamp,
          "action" => action,
          "amount" => amount,
          "username" => username,
          "btc_price" => btc_price
        } = payload,
        socket
      ) do
    user_balance = socket.assigns[:user_balance]

    # Get the initiator's balance from the original broadcast
    initiator_balance = Map.get(payload, "initiator_balance", amount)

    # Calculate user's proportional amount based on their balance
    user_amount = calculate_proportional_amount(user_balance, initiator_balance, amount)

    push(socket, "order_log", %{
      "timestamp" => timestamp,
      "action" => action,
      "amount" => user_amount,
      "username" => username,
      "btc_price" => btc_price
    })

    {:noreply, socket}
  end

  defp get_username(socket) do
    case socket.assigns do
      %{current_user: username} when is_binary(username) ->
        username |> String.split("_") |> Enum.join(" ")

      _ ->
        "Anonymous"
    end
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

  defp random_color(num) do
    class_list = [
      "bg-red-300",
      "bg-red-400",
      "bg-red-500",
      "bg-red-600",
      "bg-red-700",
      "bg-red-800",
      "bg-orange-300",
      "bg-orange-400",
      "bg-orange-500",
      "bg-orange-600",
      "bg-orange-700",
      "bg-orange-800",
      "bg-amber-300",
      "bg-amber-400",
      "bg-amber-500",
      "bg-amber-600",
      "bg-amber-700",
      "bg-amber-800",
      "bg-yellow-300",
      "bg-yellow-400",
      "bg-yellow-500",
      "bg-yellow-600",
      "bg-yellow-700",
      "bg-yellow-800",
      "bg-lime-300",
      "bg-lime-400",
      "bg-lime-500",
      "bg-lime-600",
      "bg-lime-700",
      "bg-lime-800",
      "bg-green-300",
      "bg-green-400",
      "bg-green-500",
      "bg-green-600",
      "bg-green-700",
      "bg-green-800",
      "bg-emerald-300",
      "bg-emerald-400",
      "bg-emerald-500",
      "bg-emerald-600",
      "bg-emerald-700",
      "bg-emerald-800",
      "bg-teal-300",
      "bg-teal-400",
      "bg-teal-500",
      "bg-teal-600",
      "bg-teal-700",
      "bg-teal-800",
      "bg-cyan-300",
      "bg-cyan-400",
      "bg-cyan-500",
      "bg-cyan-600",
      "bg-cyan-700",
      "bg-cyan-800",
      "bg-sky-300",
      "bg-sky-400",
      "bg-sky-500",
      "bg-sky-600",
      "bg-sky-700",
      "bg-sky-800",
      "bg-blue-300",
      "bg-blue-400",
      "bg-blue-500",
      "bg-blue-600",
      "bg-blue-700",
      "bg-blue-800",
      "bg-indigo-300",
      "bg-indigo-400",
      "bg-indigo-500",
      "bg-indigo-600",
      "bg-indigo-700",
      "bg-indigo-800",
      "bg-violet-300",
      "bg-violet-400",
      "bg-violet-500",
      "bg-violet-600",
      "bg-violet-700",
      "bg-violet-800",
      "bg-purple-300",
      "bg-purple-400",
      "bg-purple-500",
      "bg-purple-600",
      "bg-purple-700",
      "bg-purple-800",
      "bg-fuchsia-300",
      "bg-fuchsia-400",
      "bg-fuchsia-500",
      "bg-fuchsia-600",
      "bg-fuchsia-700",
      "bg-fuchsia-800",
      "bg-pink-300",
      "bg-pink-400",
      "bg-pink-500",
      "bg-pink-600",
      "bg-pink-700",
      "bg-pink-800",
      "bg-rose-300",
      "bg-rose-400",
      "bg-rose-500",
      "bg-rose-600",
      "bg-rose-700",
      "bg-rose-800"
    ]

    class_list
    |> Enum.at(rem(num, length(class_list)))
  end
end
