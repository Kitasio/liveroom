defmodule TrackWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :track,
    pubsub_server: Track.PubSub

  @topic "active_rooms"

  def init(_opts), do: {:ok, %{}}

  def fetch(_topic, presences) do
    for {key, %{metas: metas}} <- presences, into: %{} do
      # The key is the room_id. We add an `id` field for stream compatibility.
      {key, %{id: key, room_id: key, metas: metas}}
    end
  end

  def handle_metas(_topic, %{joins: joins, leaves: leaves}, _presences, state) do
    for {_room_id, presence} <- joins do
      Phoenix.PubSub.broadcast(
        Track.PubSub,
        "proxy:#{@topic}",
        {__MODULE__, {:join, presence}}
      )
    end

    # Handle leaves. `presences` is pre-leave. We must calculate the post-leave state.
    for {_room_id, presence} <- leaves do
      Phoenix.PubSub.broadcast(
        Track.PubSub,
        "proxy:#{@topic}",
        {__MODULE__, {:leave, presence}}
      )
    end

    {:ok, state}
  end

  def list_active_rooms do
    for {key, %{metas: metas}} <- list(@topic) do
      %{id: key, room_id: key, metas: metas}
    end
  end

  def track_room(pid, room_id, meta \\ %{}) do
    track(pid, @topic, to_string(room_id), meta)
  end

  def subscribe_to_rooms, do: Phoenix.PubSub.subscribe(Track.PubSub, "proxy:#{@topic}")
end
