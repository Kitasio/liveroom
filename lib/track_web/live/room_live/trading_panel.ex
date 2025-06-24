defmodule TrackWeb.RoomLive.TradingPanel do
  use Phoenix.Component
  use TrackWeb, :live_view

  attr :is_owner, :boolean, required: true
  attr :order_price, :integer, required: true
  attr :btc_live_price, :integer, required: true
  attr :trade_state, :map, required: true
  attr :order_type, :string, default: "Market"
  attr :position_action, :string, default: "Open"
  attr :limit_price, :integer, default: nil
  attr :stop_loss, :integer, default: nil
  attr :take_profit, :integer, default: nil

  def trading_panel(assigns) do
    ~H"""
    <!-- Trading Panel -->
    <div>
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <.panel_header btc_live_price={@btc_live_price} />
          <.user_balance trade_state={@trade_state} />
          <.order_type_selector order_type={@order_type} is_owner={@is_owner} />
          <.position_action_selector position_action={@position_action} is_owner={@is_owner} />
          <.order_size_inputs
            trade_state={@trade_state}
            order_price={@order_price}
            is_owner={@is_owner}
          />
          <%= if @order_type in ["Limit", "Stop Market"] do %>
            <.limit_price_input
              order_type={@order_type}
              limit_price={@limit_price}
              is_owner={@is_owner}
            />
          <% end %>
          <.stop_loss_input stop_loss={@stop_loss} is_owner={@is_owner} />
          <.take_profit_input take_profit={@take_profit} is_owner={@is_owner} />
          <.max_size_display trade_state={@trade_state} />
          <.trade_buttons is_owner={@is_owner} />
        </div>
      </div>
    </div>
    """
  end

  attr :btc_live_price, :integer, required: true

  defp panel_header(assigns) do
    ~H"""
    <div class="card-title text-primary flex justify-between">
      <h2>
        <.icon name="hero-currency-dollar" class="w-5 h-5" /> Trading Panel
      </h2>
      <div class="flex items-center justify-center gap-2">
        <img class="w-4 h-4 inline" src="/images/btc.svg" />
        <p class="text-sm">{:erlang.float_to_binary(@btc_live_price, decimals: 2)}</p>
      </div>
    </div>
    """
  end

  attr :trade_state, :map, required: true

  defp user_balance(assigns) do
    ~H"""
    <!-- User Balance Section -->
    <div class="stats bg-base-100 border-base-300 border">
      <div class="stat">
        <div class="stat-title">Balance USD</div>
        <div class="stat-value">
          ${@trade_state.balance.usd |> Decimal.round()}
        </div>
      </div>

      <div class="stat relative">
        <div class="stat-title">Balance BTC</div>
        <div class="stat-value">{@trade_state.balance.btc |> Decimal.round(5)}</div>
      </div>
    </div>
    """
  end

  attr :order_type, :string, required: true
  attr :is_owner, :boolean, required: true

  defp order_type_selector(assigns) do
    ~H"""
    <!-- Order Type Selection -->
    <div class="form-control w-full mt-4">
      <label class="label">
        <span class="label-text font-semibold">Order Type</span>
      </label>
      <form class="join w-full">
        <input
          class="join-item btn btn-sm"
          type="radio"
          name="order_type"
          value="Market"
          checked={@order_type == "Market"}
          phx-click="update_order_type"
          aria-label="Market"
          disabled={!@is_owner}
        />
        <input
          class="join-item btn btn-sm"
          type="radio"
          name="order_type"
          value="Limit"
          checked={@order_type == "Limit"}
          phx-click="update_order_type"
          aria-label="Limit"
          disabled={!@is_owner}
        />
        <input
          class="join-item btn btn-sm"
          type="radio"
          name="order_type"
          value="Stop Market"
          checked={@order_type == "Stop Market"}
          phx-click="update_order_type"
          aria-label="Stop Market"
          disabled={!@is_owner}
        />
      </form>
    </div>
    """
  end

  attr :position_action, :string, required: true
  attr :is_owner, :boolean, required: true

  defp position_action_selector(assigns) do
    ~H"""
    <!-- Position Action -->
    <div class="form-control w-full mt-4">
      <form class="join w-full">
        <input
          class="join-item btn btn-sm flex-1"
          type="radio"
          name="position_action"
          value="Open"
          checked={@position_action == "Open"}
          phx-click="update_position_action"
          aria-label="Open"
          disabled={!@is_owner}
        />
        <input
          class="join-item btn btn-sm flex-1"
          type="radio"
          name="position_action"
          value="Close"
          checked={@position_action == "Close"}
          phx-click="update_position_action"
          aria-label="Close"
          disabled={!@is_owner}
        />
      </form>
    </div>
    """
  end

  attr :trade_state, :map, required: true
  attr :order_price, :integer, required: true
  attr :is_owner, :boolean, required: true

  defp order_size_inputs(assigns) do
    ~H"""
    <!-- Order Amount -->
    <div class="form-control w-full mt-6">
      <label class="label">
        <span class="label-text font-semibold">Size (USD)</span>
      </label>
      <form>
        <input
          type="range"
          min="0"
          max={@trade_state.margin_info.max_buy_size_usd}
          value={@order_price}
          class="range w-full my-3"
          step="100"
          id="price-range"
          name="price-range"
          phx-input="update_order_price"
          phx-change="update_order_price"
          disabled={!@is_owner}
        />
        <input
          id="price-input"
          min="0"
          step="100"
          name="price"
          value={@order_price}
          type="number"
          class="input input-bordered w-full"
          placeholder="Enter amount to trade"
          phx-change="update_order_price"
          disabled={!@is_owner}
        />
      </form>
    </div>
    """
  end

  attr :order_type, :string, required: true
  attr :limit_price, :integer, default: nil
  attr :is_owner, :boolean, required: true

  defp limit_price_input(assigns) do
    ~H"""
    <!-- Limit Price (shown only for Limit and Stop Market orders) -->
    <form class="form-control w-full mt-4">
      <label class="label">
        <span class="label-text font-semibold">
          {if @order_type == "Limit", do: "Limit Price", else: "Stop Price"} (USD)
        </span>
      </label>
      <input
        id="limit-price-input"
        name="limit_price"
        value={@limit_price}
        type="number"
        step="0.01"
        class="input input-bordered w-full"
        placeholder={
          if @order_type == "Limit", do: "Enter limit price", else: "Enter stop price"
        }
        phx-change="update_limit_price"
        disabled={!@is_owner}
      />
    </form>
    """
  end

  attr :stop_loss, :integer, default: nil
  attr :is_owner, :boolean, required: true

  defp stop_loss_input(assigns) do
    ~H"""
    <!-- Stop Loss -->
    <form class="form-control w-full mt-4">
      <label class="label">
        <span class="label-text font-semibold">Stop Loss (USD)</span>
      </label>
      <input
        id="stop-loss-input"
        name="stop_loss"
        value={@stop_loss}
        type="number"
        step="0.01"
        class="input input-bordered w-full"
        placeholder="Optional stop loss price"
        phx-change="update_stop_loss"
        disabled={!@is_owner}
      />
    </form>
    """
  end

  attr :take_profit, :integer, default: nil
  attr :is_owner, :boolean, required: true

  defp take_profit_input(assigns) do
    ~H"""
    <!-- Take Profit -->
    <form class="form-control w-full mt-4">
      <label class="label">
        <span class="label-text font-semibold">Take Profit (USD)</span>
      </label>
      <input
        id="take-profit-input"
        name="take_profit"
        value={@take_profit}
        type="number"
        step="0.01"
        class="input input-bordered w-full"
        placeholder="Optional take profit price"
        phx-change="update_take_profit"
        disabled={!@is_owner}
      />
    </form>
    """
  end

  attr :trade_state, :map, required: true

  defp max_size_display(assigns) do
    ~H"""
    <!-- Max Size Display -->
    <div class="mt-4 p-3 rounded-lg">
      <div class="text-sm font-medium text-base-content mb-2">Max Size:</div>
      <div class="flex justify-between items-center text-sm">
        <span class="text-error">
          {@trade_state.margin_info.max_sell_size_usd} USD
        </span>
        <span class="text-base-content/50">/</span>
        <span class="text-success">
          {@trade_state.margin_info.max_buy_size_usd} USD
        </span>
      </div>
    </div>
    """
  end

  attr :is_owner, :boolean, required: true

  defp trade_buttons(assigns) do
    ~H"""
    <!-- Trading Buttons -->
    <div class="card-actions justify-center mt-6">
      <div class="join w-full">
        <button
          phx-click="buy"
          id="buy-btn"
          class="btn btn-success join-item flex-1"
          disabled={!@is_owner}
        >
          <.icon name="hero-arrow-trending-up" class="w-4 h-4" /> Buy BTC
        </button>
        <button
          phx-click="sell"
          id="sell-btn"
          class="btn btn-error join-item flex-1"
          disabled={!@is_owner}
        >
          <.icon name="hero-arrow-trending-down" class="w-4 h-4" /> Sell BTC
        </button>
      </div>
    </div>
    """
  end
end
