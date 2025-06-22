defmodule Track.CurrencyConverter do
  @moduledoc """
  Provides functions for converting between different currency units (sats, BTC, USD).
  """

  # Converts sats (integer or string) to BTC (string)
  def sats_to_btc(sats) when is_integer(sats) or is_binary(sats) do
    Decimal.div(Decimal.new(sats), 100_000_000) |> to_string()
  end

  # Converts sats (Decimal) to BTC (string)
  def sats_to_btc(sats) when is_struct(sats, Decimal) do
    Decimal.div(sats, 100_000_000) |> to_string()
  end

  # Converts BTC (Decimal) to sats (string)
  def btc_to_sats(btc) when is_struct(btc, Decimal) do
    Decimal.mult(btc, 100_000_000) |> to_string()
  end

  # Converts sats (integer, string, or Decimal) to USD (string) using BTC price (integer, float, string, or Decimal)
  def sats_to_usd(sats, btc_price)
      when (is_integer(sats) or is_binary(sats) or is_struct(sats, Decimal)) and
             (is_integer(btc_price) or is_float(btc_price) or is_binary(btc_price) or
                is_struct(btc_price, Decimal)) do
    sats_decimal = if is_struct(sats, Decimal), do: sats, else: Decimal.new(sats)

    btc_price_decimal =
      cond do
        is_struct(btc_price, Decimal) -> btc_price
        is_float(btc_price) -> Decimal.from_float(btc_price)
        # Handles integer and binary
        true -> Decimal.new(btc_price)
      end

    btc = Decimal.div(sats_decimal, 100_000_000) # Keep as Decimal for intermediate calculation
    Decimal.mult(btc, btc_price_decimal) |> to_string()
  end

  # Converts BTC (Decimal) to USD (string) using BTC price (integer, float, string, or Decimal)
  def btc_to_usd(btc, btc_price)
      when is_struct(btc, Decimal) and
             (is_integer(btc_price) or is_float(btc_price) or is_binary(btc_price)) do
    btc_price_decimal =
      if is_float(btc_price), do: Decimal.from_float(btc_price), else: Decimal.new(btc_price)

    Decimal.mult(btc, btc_price_decimal) |> to_string()
  end

  def btc_to_usd(btc, btc_price) when is_struct(btc, Decimal) and is_struct(btc_price, Decimal) do
    Decimal.mult(btc, btc_price) |> to_string()
  end
end
