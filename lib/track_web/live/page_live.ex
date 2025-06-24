defmodule TrackWeb.PageLive do
  use TrackWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>Hello world</div>
    """
  end
end
