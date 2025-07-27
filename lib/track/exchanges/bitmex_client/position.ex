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

  def get_positions(%Scope{} = scope, symbol \\ "XBTUSD") do
    case BitmexClient.API.get_positions(scope, symbol) do
      {:ok, positions_list} ->
        result = positions_list |> Enum.map(&from_map/1)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
