defmodule TrackWeb.RoomController do
  use TrackWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: ~p"/rooms/#{conn.assigns[:current_scope].user.id}")
  end
end
