defmodule Track.Crypto do
  @binance_kline_url "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=5m&limit=100"

  def get_candles do
    Req.get!(@binance_kline_url)
    |> Map.fetch!(:body)
    |> Enum.map(fn [time, open, high, low, close | _] ->
      %{
        # Convert ms to seconds
        time: div(time, 1000),
        open: String.to_float(open),
        high: String.to_float(high),
        low: String.to_float(low),
        close: String.to_float(close)
      }
    end)
  end
end
