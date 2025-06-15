defmodule TrackWeb.RoomController do
  use TrackWeb, :controller

  def index(conn, _params) do
    redirect_to_user_room(conn)
  end

  defp redirect_to_user_room(conn) do
    case conn.assigns[:anon_user] do
      nil ->
        redirect(conn, to: ~p"/")

      username ->
        redirect(conn, to: ~p"/rooms/#{username}")
    end
  end
end
