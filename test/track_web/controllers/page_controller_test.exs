defmodule TrackWeb.PageControllerTest do
  use TrackWeb.ConnCase
  import Track.AccountsFixtures, only: [user_fixture: 0]

  test "GET /", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user) |> get(~p"/")
    assert html_response(conn, 200) =~ "LiveRoom"
  end
end
