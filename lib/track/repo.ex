defmodule Track.Repo do
  use Ecto.Repo,
    otp_app: :track,
    adapter: Ecto.Adapters.Postgres
end
