defmodule Track.CurrencyConverterTest do
  use ExUnit.Case, async: true

  alias Track.CurrencyConverter
  import Decimal # Need this for Decimal.new and Decimal.compare

  # Helper to compare string representations numerically
  defp assert_numeric_equal(actual_str, expected_str) do
    actual_decimal = Decimal.new(actual_str)
    expected_decimal = Decimal.new(expected_str)
    assert Decimal.compare(actual_decimal, expected_decimal) == :eq
  end

  test "sats_to_btc converts integer sats to string BTC" do
    sats = 100_000_000
    expected_btc = "1"
    assert_numeric_equal(CurrencyConverter.sats_to_btc(sats), expected_btc)
  end

  test "sats_to_btc converts string sats to string BTC" do
    sats = "200000000"
    expected_btc = "2"
    assert_numeric_equal(CurrencyConverter.sats_to_btc(sats), expected_btc)
  end

  test "sats_to_btc converts Decimal sats to string BTC" do
    sats = Decimal.new(50_000_000)
    expected_btc = "0.5"
    assert_numeric_equal(CurrencyConverter.sats_to_btc(sats), expected_btc)
  end

  test "btc_to_sats converts Decimal BTC to string sats" do
    btc = Decimal.new("0.000001")
    expected_sats = "100"
    assert_numeric_equal(CurrencyConverter.btc_to_sats(btc), expected_sats)
  end

  test "sats_to_usd converts integer sats and float btc_price to string USD" do
    sats = 100_000_000
    btc_price = 50000.0
    expected_usd = "50000"
    assert_numeric_equal(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd)
  end

  test "sats_to_usd converts string sats and integer btc_price to string USD" do
    sats = "50000000"
    btc_price = 60000
    expected_usd = "30000"
    assert_numeric_equal(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd)
  end

  test "sats_to_usd converts Decimal sats and string btc_price to string USD" do
    sats = Decimal.new(25_000_000)
    btc_price = "70000.50"
    expected_usd = "17500.125"
    assert_numeric_equal(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd)
  end

  test "sats_to_usd converts Decimal sats and Decimal btc_price to string USD" do
    sats = Decimal.new(10_000_000)
    btc_price = Decimal.new("80000.75")
    expected_usd = "8000.075"
    assert_numeric_equal(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd)
  end

  test "btc_to_usd converts Decimal BTC and float btc_price to string USD" do
    btc = Decimal.new("0.5")
    btc_price = 50000.0
    expected_usd = "25000"
    assert_numeric_equal(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd)
  end

  test "btc_to_usd converts Decimal BTC and integer btc_price to string USD" do
    btc = Decimal.new("0.25")
    btc_price = 60000
    expected_usd = "15000"
    assert_numeric_equal(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd)
  end

  test "btc_to_usd converts Decimal BTC and string btc_price to string USD" do
    btc = Decimal.new("0.1")
    btc_price = "70000.50"
    expected_usd = "7000.05"
    assert_numeric_equal(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd)
  end

  test "btc_to_usd converts Decimal BTC and Decimal btc_price to string USD" do
    btc = Decimal.new("0.01")
    btc_price = Decimal.new("80000.75")
    expected_usd = "800.0075"
    assert_numeric_equal(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd)
  end
end
