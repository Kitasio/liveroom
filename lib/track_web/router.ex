defmodule TrackWeb.Router do
  use TrackWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TrackWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug TrackWeb.AnonUser, nil
    plug :put_user_token
  end

  defp put_user_token(conn, _) do
    if anon_user = conn.assigns[:anon_user] do
      token = Phoenix.Token.sign(conn, "user socket", anon_user)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TrackWeb do
    pipe_through :api

    get "/candles", CandlesController, :index
  end

  scope "/", TrackWeb do
    pipe_through :browser

    live "/", PageLive
    live "/price", PriceLive
    get "/rooms", RoomController, :index
    live "/rooms/:room_id", RoomLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", TrackWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:track, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TrackWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
