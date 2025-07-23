defmodule Track.Exchanges.BitmexClient.Margin do
  alias Track.Exchanges.BitmexClient
  alias Track.Accounts.Scope

  @type t :: %__MODULE__{
          account: integer(),
          account_id: integer(),
          amount: integer(),
          available_margin: integer(),
          currency: String.t(),
          excess_margin: integer(),
          foreign_margin_balance: integer(),
          foreign_requirement: integer(),
          gross_comm: integer(),
          gross_mark_value: integer(),
          gross_open_cost: integer(),
          gross_open_premium: integer(),
          init_margin: integer(),
          maint_margin: integer(),
          margin_balance: integer(),
          margin_leverage: number(),
          margin_used_pcnt: number(),
          realised_pnl: integer(),
          risk_limit: integer(),
          risk_value: integer(),
          target_excess_margin: integer(),
          timestamp: String.t(),
          unrealised_pnl: integer(),
          wallet_balance: integer(),
          withdrawable_margin: integer()
        }

  defstruct [
    :account,
    :account_id,
    :amount,
    :available_margin,
    :currency,
    :excess_margin,
    :foreign_margin_balance,
    :foreign_requirement,
    :gross_comm,
    :gross_mark_value,
    :gross_open_cost,
    :gross_open_premium,
    :init_margin,
    :maint_margin,
    :margin_balance,
    :margin_leverage,
    :margin_used_pcnt,
    :realised_pnl,
    :risk_limit,
    :risk_value,
    :target_excess_margin,
    :timestamp,
    :unrealised_pnl,
    :wallet_balance,
    :withdrawable_margin
  ]

  @spec from_map(map()) :: t()
  def from_map(margin_map) when is_map(margin_map) do
    %__MODULE__{
      account: Map.get(margin_map, "account"),
      account_id: Map.get(margin_map, "accountId"),
      amount: Map.get(margin_map, "amount"),
      available_margin: Map.get(margin_map, "availableMargin"),
      currency: Map.get(margin_map, "currency"),
      excess_margin: Map.get(margin_map, "excessMargin"),
      foreign_margin_balance: Map.get(margin_map, "foreignMarginBalance"),
      foreign_requirement: Map.get(margin_map, "foreignRequirement"),
      gross_comm: Map.get(margin_map, "grossComm"),
      gross_mark_value: Map.get(margin_map, "grossMarkValue"),
      gross_open_cost: Map.get(margin_map, "grossOpenCost"),
      gross_open_premium: Map.get(margin_map, "grossOpenPremium"),
      init_margin: Map.get(margin_map, "initMargin"),
      maint_margin: Map.get(margin_map, "maintMargin"),
      margin_balance: Map.get(margin_map, "marginBalance"),
      margin_leverage: Map.get(margin_map, "marginLeverage"),
      margin_used_pcnt: Map.get(margin_map, "marginUsedPcnt"),
      realised_pnl: Map.get(margin_map, "realisedPnl"),
      risk_limit: Map.get(margin_map, "riskLimit"),
      risk_value: Map.get(margin_map, "riskValue"),
      target_excess_margin: Map.get(margin_map, "targetExcessMargin"),
      timestamp: Map.get(margin_map, "timestamp"),
      unrealised_pnl: Map.get(margin_map, "unrealisedPnl"),
      wallet_balance: Map.get(margin_map, "walletBalance"),
      withdrawable_margin: Map.get(margin_map, "withdrawableMargin")
    }
  end

  @doc """
  Fetches user's margin balance for a specific currency.
  """
  def get_user_balance(%Scope{} = scope, currency) do
    case BitmexClient.API.get_balance(scope, currency) do
      {:ok, balance_list} ->
        result = balance_list |> Enum.map(fn balance_map -> from_map(balance_map) end)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
