ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Track.Repo, :manual)

Mox.defmock(Track.Exchanges.BitmexClient.MockAPI, for: Track.Exchanges.BitmexClient.API)
Application.put_env(:track, :bitmex_client, Track.Exchanges.BitmexClient.MockAPI)

Mox.defmock(Track.Exchanges.Bitmex.MockAPI, for: Track.Exchanges.Bitmex.API)
Application.put_env(:track, :bitmex_api_module, Track.Exchanges.Bitmex.MockAPI)

Mox.defmock(Track.Exchanges.MockAccountAPI, for: Track.Exchanges.AccountAPI)
Mox.defmock(Track.Exchanges.MockMarketDataAPI, for: Track.Exchanges.MarketDataAPI)
