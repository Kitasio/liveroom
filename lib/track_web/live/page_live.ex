defmodule TrackWeb.PageLive do
  use TrackWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        TrackWeb.Presence.subscribe_to_rooms()

        socket
        |> stream(:rooms, TrackWeb.Presence.list_active_rooms())
      else
        stream(socket, :rooms, [])
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="p-4 md:p-8">
        <h1 class="text-3xl font-bold mb-6">Welcome!</h1>
        <h2 class="text-2xl font-semibold mb-4">Active Rooms</h2>
        <ul id="active-rooms" class="space-y-3" phx-update="stream">
          <li id="no-rooms-msg" class="text-base-content/70 only:block hidden">
            There are currently no active rooms.
          </li>
          <li
            :for={{dom_id, room} <- @streams.rooms}
            id={dom_id}
            class="p-4 bg-base-200 rounded-box flex justify-between items-center"
          >
            <div>
              <p class="font-bold">Room #{room.room_id}</p>
              <span class="text-sm text-base-content/70">
                {n = length(room.metas)}
                {ngettext("%{count} owner present", "%{count} owners present", n, count: n)}
              </span>
            </div>
            <.link href={~p"/rooms/#{room.room_id}"} class="btn btn-primary btn-sm">
              Join Room
            </.link>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end

  def handle_info({TrackWeb.Presence, {:join, room_data}}, socket) do
    {:noreply, stream_insert(socket, :rooms, room_data)}
  end

  def handle_info({TrackWeb.Presence, {:leave, room_data}}, socket) do
    {:noreply, stream_delete(socket, :rooms, room_data)}
  end
end
