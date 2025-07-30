defmodule Track.Exchanges.BitmexClient.Position do
  alias Track.Exchanges.BitmexClient
  alias Track.Accounts.Scope

  @type t :: %__MODULE__{
          current_qty: integer() | nil,
          is_open: boolean() | nil,
          leverage: integer() | nil,
          realised_pnl: String.t() | nil,
          unrealised_pnl: String.t() | nil
        }

  defstruct [:current_qty, :is_open, :leverage, :realised_pnl, :unrealised_pnl]

  def from_map(position_map) when is_map(position_map) do
    %__MODULE__{
      current_qty: Map.get(position_map, "currentQty"),
      is_open: Map.get(position_map, "isOpen"),
      leverage: Map.get(position_map, "leverage"),
      realised_pnl: Map.get(position_map, "realisedPnl") |> to_string(),
      unrealised_pnl: Map.get(position_map, "unrealisedPnl") |> to_string()
    }
  end

  @doc """
  Fetches user positions from Bitmex API, converting them to Position struct

  ## Examples

      iex> Track.Exchanges.BitmexClient.Position.get_positions(scope, "XBTUSD")
      {:ok,
       [
         %Track.Exchanges.BitmexClient.Position{
           is_open: false,
           realised_pnl: "0",
           unrealised_pnl: "0",
           current_qty: 0,
           leverage: 100
         }
       ]}

  """
  def get_positions(%Scope{} = scope, symbol \\ "XBTUSD") do
    fetch_positions_from_api(scope, symbol)
    |> parse_response()
  end

  @doc false
  defp fetch_positions_from_api(scope, symbol) do
    BitmexClient.API.get_positions(scope, symbol)
  end

  @doc false
  defp parse_response({:ok, positions}) do
    result = positions |> Enum.map(&from_map/1)
    {:ok, result}
  end

  defp parse_response({:error, reason}), do: {:error, reason}
end
