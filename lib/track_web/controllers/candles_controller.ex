defmodule TrackWeb.CandlesController do
  use TrackWeb, :controller

  def index(conn, _params) do
    data = Track.Crypto.get_candles()
    json(conn, data)
  end
end
