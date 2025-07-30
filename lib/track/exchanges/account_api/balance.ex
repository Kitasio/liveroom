defmodule Track.Exchanges.AccountAPI.Balance do
  @type t :: %__MODULE__{
          currency: String.t(),
          amount: String.t()
        }

  @enforce_keys [:currency, :amount]
  defstruct [:currency, :amount]
end
