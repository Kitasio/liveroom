defmodule Track.Exchanges.BitmexClient.API do
  alias Track.Accounts.Scope

  @callback get_balance(scope :: Scope, currency :: String.t()) :: {:ok, [map()]} | {:error, term}

  def get_balance(scope, currency), do: impl().get_balance(scope, currency)
  defp impl, do: Application.get_env(:track, :bitmex_client, Track.Exchanges.BitmexClient.APIImpl)
end
