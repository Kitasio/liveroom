defmodule Track.Exchanges.BitmexClient.API do
  alias Track.Accounts.Scope

  @callback get_balance(scope :: Scope, currency :: String.t()) :: {:ok, [map()]} | {:error, term}
  @callback get_instrument(scope :: Scope, symbol :: String.t() | nil) ::
              {:ok, [map()]} | {:error, term}
  @callback get_positions(scope :: Scope, symbol :: String.t() | nil) ::
              {:ok, [map()]} | {:error, term}

  def get_balance(scope, currency), do: impl().get_balance(scope, currency)
  def get_instrument(scope, symbol), do: impl().get_instrument(scope, symbol)
  def get_positions(scope, symbol), do: impl().get_positions(scope, symbol)
  defp impl, do: Application.get_env(:track, :bitmex_client, Track.Exchanges.BitmexClient.APIImpl)
end
