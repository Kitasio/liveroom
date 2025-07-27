defmodule Track.Exchanges.BitmexClient.API do
  alias Track.Accounts.Scope

  @callback get_balance(scope :: Scope, currency :: String.t()) :: {:ok, [map()]} | {:error, term}
  @callback get_instrument(scope :: Scope, symbol :: String.t() | nil) ::
              {:ok, [map()]} | {:error, term}
  @callback get_positions(scope :: Scope, symbol :: String.t() | nil) ::
              {:ok, [map()]} | {:error, term}

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

  defp impl, do: Application.get_env(:track, :bitmex_client, Track.Exchanges.BitmexClient.APIImpl)
end
