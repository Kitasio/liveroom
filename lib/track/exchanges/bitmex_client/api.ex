defmodule Track.Exchanges.BitmexClient.API do
  alias Track.Accounts.Scope

  @callback get_balance(scope :: Scope, currency :: String.t()) :: {:ok, [map()]} | {:error, term}
  @callback get_instrument(scope :: Scope, symbol :: String.t() | nil) ::
              {:ok, [map()]} | {:error, term}
  @callback get_positions(scope :: Scope, symbol :: String.t() | nil) ::
              {:ok, [map()]} | {:error, term}

  @callback place_market_order(
              scope :: Scope.t(),
              symbol :: String.t(),
              side :: String.t(),
              quantity :: integer()
            ) :: {:ok, map()} | {:error, term}

  @doc """
  Fetches user balance from Bitmex API

  ## Examples

      iex> Track.Exchanges.BitmexClient.API.get_balance(scope, "XBt")
      {:ok, [%{"account" => 421_399, ...other fields}]}

  """
  def get_balance(scope, currency), do: impl().get_balance(scope, currency)

  @doc """
  Fetches instrument data from Bitmex API

  ## Examples

      iex> Track.Exchanges.BitmexClient.API.get_instrument(scope, "XBTUSD")
      {:ok, [%{"lastPrice" => 90999}]}

  """
  def get_instrument(scope, symbol), do: impl().get_instrument(scope, symbol)

  @doc """
  Fetches user positions from Bitmex API

  ## Examples

      iex> Track.Exchanges.BitmexClient.API.get_positions(scope, "XBTUSD")
      {:ok,
       [
         %{
           "isOpen" => false,
           "realisedPnl" => 0,
           "unrealisedPnl" => 0,
           "currentQty" => 0,
           "leverage" => 100
         }
       ]}

  """
  def get_positions(scope, symbol), do: impl().get_positions(scope, symbol)

  @doc """
  Places a market order.

  ## Examples

      iex> Track.Exchanges.BitmexClient.API.place_market_order(scope, "XBTUSD", "Buy", 100)
      {:ok, %{"orderID" => "some-uuid", ...}}
  """
  def place_market_order(scope, symbol, side, quantity),
    do: impl().place_market_order(scope, symbol, side, quantity)

  defp impl, do: Application.get_env(:track, :bitmex_client, Track.Exchanges.BitmexClient.APIImpl)
end
