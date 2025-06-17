defmodule TrackWeb.BitmexSettingLive.Index do
  use TrackWeb, :live_view

  alias Track.Exchanges

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Bitmex settings
        <:actions>
          <.button variant="primary" navigate={~p"/bitmex_settings/new"}>
            <.icon name="hero-plus" /> New Bitmex setting
          </.button>
        </:actions>
      </.header>

      <.table
        id="bitmex_settings"
        rows={@streams.bitmex_settings}
        row_click={fn {_id, bitmex_setting} -> JS.navigate(~p"/bitmex_settings/#{bitmex_setting}") end}
      >
        <:col :let={{_id, bitmex_setting}} label="Api key">{bitmex_setting.api_key}</:col>
        <:col :let={{_id, bitmex_setting}} label="Api secret">{bitmex_setting.api_secret}</:col>
        <:action :let={{_id, bitmex_setting}}>
          <div class="sr-only">
            <.link navigate={~p"/bitmex_settings/#{bitmex_setting}"}>Show</.link>
          </div>
          <.link navigate={~p"/bitmex_settings/#{bitmex_setting}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, bitmex_setting}}>
          <.link
            phx-click={JS.push("delete", value: %{id: bitmex_setting.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Exchanges.subscribe_bitmex_settings(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Bitmex settings")
     |> stream(:bitmex_settings, Exchanges.list_bitmex_settings(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bitmex_setting = Exchanges.get_bitmex_setting!(socket.assigns.current_scope, id)
    {:ok, _} = Exchanges.delete_bitmex_setting(socket.assigns.current_scope, bitmex_setting)

    {:noreply, stream_delete(socket, :bitmex_settings, bitmex_setting)}
  end

  @impl true
  def handle_info({type, %Track.Exchanges.BitmexSetting{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :bitmex_settings, Exchanges.list_bitmex_settings(socket.assigns.current_scope), reset: true)}
  end
end
