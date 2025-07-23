ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Track.Repo, :manual)

Mox.defmock(Track.Exchanges.BitmexClient.MockAPI, for: Track.Exchanges.BitmexClient.API)
Application.put_env(:track, :bitmex_client, Track.Exchanges.BitmexClient.MockAPI)
