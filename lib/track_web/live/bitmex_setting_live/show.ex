defmodule TrackWeb.BitmexSettingLive.Show do
  use TrackWeb, :live_view

  alias Track.Exchanges

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Bitmex setting {@bitmex_setting.id}
        <:subtitle>This is a bitmex_setting record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/bitmex_settings"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/bitmex_settings/#{@bitmex_setting}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit bitmex_setting
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Api key">{@bitmex_setting.api_key}</:item>
        <:item title="Api secret">{@bitmex_setting.api_secret}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Exchanges.subscribe_bitmex_settings(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Bitmex setting")
     |> assign(:bitmex_setting, Exchanges.get_bitmex_setting!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Track.Exchanges.BitmexSetting{id: id} = bitmex_setting},
        %{assigns: %{bitmex_setting: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :bitmex_setting, bitmex_setting)}
  end

  def handle_info(
        {:deleted, %Track.Exchanges.BitmexSetting{id: id}},
        %{assigns: %{bitmex_setting: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current bitmex_setting was deleted.")
     |> push_navigate(to: ~p"/bitmex_settings")}
  end

  def handle_info({type, %Track.Exchanges.BitmexSetting{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
