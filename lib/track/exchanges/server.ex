defmodule Track.Exchanges.Server do
  alias Track.Exchanges.AccountAPI.Balance
  alias Track.Accounts.Scope
  alias Track.Exchanges.Account
  use GenServer

  def start_link(%Scope{} = scope) do
    GenServer.start_link(__MODULE__, scope)
  end

  def subscribe_exchanges_server(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Track.PubSub, "user:#{key}:exchanges_server")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Track.PubSub, "user:#{key}:exchanges_server", message)
  end

  def account_balance(server) do
    GenServer.call(server, :get_balance)
  end

  @impl true
  def init(scope) do
    state = %{
      account_module: Track.Exchanges.Bitmex.Account,
      scope: scope,
      account_balance: %Balance{currency: "XBt", amount: "0"}
    }

    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_call(:get_balance, _from, state) do
    {:reply, state.account_balance, state}
  end

  @impl true
  def handle_info(:work, state) do
    balance_result = Account.get_balance(state.account_module, state.scope, "XBt")
    state = %{state | account_balance: balance_result}

    broadcast(state.scope, {:updated_balance, balance_result})

    schedule_work()

    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, :timer.seconds(5))
  end
end
