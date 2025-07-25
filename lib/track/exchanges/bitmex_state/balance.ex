defmodule Track.Exchanges.BitmexState.Balance do
  alias Track.Exchanges.BitmexClient.Instrument
  alias Track.Exchanges.BitmexClient.Margin
  alias Track.CurrencyConverter
  alias Track.Accounts.Scope

  @type t :: %__MODULE__{
          usd: String.t(),
          sats: String.t(),
          btc: String.t()
        }
  defstruct usd: "0", sats: "0", btc: "0"

  def new() do
    %__MODULE__{
      usd: "0",
      sats: "0",
      btc: "0"
    }
  end

  def update_usd(%__MODULE__{} = balance, usd) when is_binary(usd) do
    %__MODULE__{balance | usd: usd}
  end

  def update_sats(%__MODULE__{} = balance, sats) when is_binary(sats) do
    %__MODULE__{balance | sats: sats}
  end

  def update_btc(%__MODULE__{} = balance, btc) when is_binary(btc) do
    %__MODULE__{balance | btc: btc}
  end

  @doc """
  Fetches user balance from Bitmex API

  Converts to different currencies using fetched BTC price

  ## Examples

      iex> Track.Exchanges.BitmexState.fetch_balance(scope)
      %Track.Exchanges.BitmexState.Balance{sats: "18583", btc: "0.00018583", usd: "22.071530841"

  """
  def fetch_balance(%Scope{} = scope) do
    {sats_balance, btc_price} = fetch_balance_and_price(scope)

    new()
    |> update_usd(CurrencyConverter.sats_to_usd(sats_balance, btc_price))
    |> update_sats(to_string(sats_balance))
    |> update_btc(CurrencyConverter.sats_to_btc(sats_balance))
  end

  defp fetch_balance_and_price(scope) do
    tasks = [
      fn -> Margin.get_user_balance(scope, "XBt") end,
      fn -> Instrument.get_instrument(scope) end
    ]

    [balance_result, instrument_result] =
      tasks
      |> Task.async_stream(& &1.(), timeout: 10_000)
      |> Enum.map(fn {:ok, result} -> result end)

    {:ok, [%{amount: sats_int} | _tail]} = balance_result
    {:ok, [%{last_price: btc_price_float} | _tail]} = instrument_result

    {sats_int, btc_price_float}
  end
end
