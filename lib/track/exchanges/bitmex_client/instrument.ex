defmodule Track.Exchanges.BitmexClient.Instrument do
  alias Track.Exchanges.BitmexClient
  alias Track.Accounts.Scope

  @type t :: %__MODULE__{
          last_price: integer() | nil
        }

  defstruct [:last_price]

  def from_map(instrument_map) when is_map(instrument_map) do
    %__MODULE__{
      last_price: Map.get(instrument_map, "lastPrice")
    }
  end

  def get_instrument(%Scope{} = scope, symbol \\ "XBTUSD") do
    case BitmexClient.API.get_instrument(scope, symbol) do
      {:ok, instrument_list} ->
        result = instrument_list |> Enum.map(&from_map/1)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
