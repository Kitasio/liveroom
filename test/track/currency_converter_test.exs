defmodule Track.CurrencyConverterTest do
  use ExUnit.Case, async: true

  alias Track.CurrencyConverter
  import Decimal

  test "sats_to_btc converts integer sats to Decimal BTC" do
    sats = 100_000_000
    expected_btc = Decimal.new(1)
    assert Decimal.compare(CurrencyConverter.sats_to_btc(sats), expected_btc) == :eq
  end

  test "sats_to_btc converts string sats to Decimal BTC" do
    sats = "200000000"
    expected_btc = Decimal.new(2)
    assert Decimal.compare(CurrencyConverter.sats_to_btc(sats), expected_btc) == :eq
  end

  test "sats_to_btc converts Decimal sats to Decimal BTC" do
    sats = Decimal.new(50_000_000)
    expected_btc = Decimal.new("0.5")
    assert Decimal.compare(CurrencyConverter.sats_to_btc(sats), expected_btc) == :eq
  end

  test "btc_to_sats converts Decimal BTC to Decimal sats" do
    btc = Decimal.new("0.000001")
    expected_sats = Decimal.new(100)
    assert Decimal.compare(CurrencyConverter.btc_to_sats(btc), expected_sats) == :eq
  end

  test "sats_to_usd converts integer sats and float btc_price to Decimal USD" do
    sats = 100_000_000
    btc_price = 50000.0
    expected_usd = Decimal.new(50000)
    assert Decimal.compare(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd) == :eq
  end

  test "sats_to_usd converts string sats and integer btc_price to Decimal USD" do
    sats = "50000000"
    btc_price = 60000
    expected_usd = Decimal.new(30000)
    assert Decimal.compare(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd) == :eq
  end

  test "sats_to_usd converts Decimal sats and string btc_price to Decimal USD" do
    sats = Decimal.new(25_000_000)
    btc_price = "70000.50"
    expected_usd = Decimal.new("17500.125")
    assert Decimal.compare(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd) == :eq
  end

  test "sats_to_usd converts Decimal sats and Decimal btc_price to Decimal USD" do
    sats = Decimal.new(10_000_000)
    btc_price = Decimal.new("80000.75")
    expected_usd = Decimal.new("8000.075")
    assert Decimal.compare(CurrencyConverter.sats_to_usd(sats, btc_price), expected_usd) == :eq
  end

  test "btc_to_usd converts Decimal BTC and float btc_price to Decimal USD" do
    btc = Decimal.new("0.5")
    btc_price = 50000.0
    expected_usd = Decimal.new(25000)
    assert Decimal.compare(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd) == :eq
  end

  test "btc_to_usd converts Decimal BTC and integer btc_price to Decimal USD" do
    btc = Decimal.new("0.25")
    btc_price = 60000
    expected_usd = Decimal.new(15000)
    assert Decimal.compare(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd) == :eq
  end

  test "btc_to_usd converts Decimal BTC and string btc_price to Decimal USD" do
    btc = Decimal.new("0.1")
    btc_price = "70000.50"
    expected_usd = Decimal.new("7000.05")
    assert Decimal.compare(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd) == :eq
  end

  test "btc_to_usd converts Decimal BTC and Decimal btc_price to Decimal USD" do
    btc = Decimal.new("0.01")
    btc_price = Decimal.new("80000.75")
    expected_usd = Decimal.new("800.0075")
    assert Decimal.compare(CurrencyConverter.btc_to_usd(btc, btc_price), expected_usd) == :eq
  end
end
