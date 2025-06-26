defmodule TrackWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use TrackWeb, :html

  embed_templates "layouts/*"

  attr :wide, :boolean, default: false
  attr :current_scope, :any
  attr :flash, :any

  slot :inner_block

  def app(assigns) do
    ~H"""
    <header class="navbar bg-base-100 shadow-sm">
      <div class="navbar-start">
        <.link href="/" class="btn btn-ghost text-xl">LiveRoom</.link>
      </div>
      <div class="navbar-end">
        <ul class="menu menu-horizontal hidden sm:flex items-center gap-4 px-1">
          <%= if @current_scope do %>
            <li>
              <span>{@current_scope.user.email}</span>
            </li>
            <li>
              <.link href={~p"/rooms/#{@current_scope.user.id}"}>My room</.link>
            </li>
            <li>
              <.link href={~p"/bitmex_settings"}>API Keys</.link>
            </li>
            <li>
              <.link href={~p"/users/settings"}>Settings</.link>
            </li>
            <li>
              <.link href={~p"/users/log-out"} method="delete">Log out</.link>
            </li>
          <% else %>
            <li>
              <.link href={~p"/users/register"}>Register</.link>
            </li>
            <li>
              <.link href={~p"/users/log-in"}>Log in</.link>
            </li>
          <% end %>
          <li>
            <.theme_toggle />
          </li>
        </ul>

        <div class="flex items-center sm:hidden">
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="btn btn-ghost">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
            </label>
            <ul
              tabindex="0"
              class="menu menu-compact dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52 z-[1]"
            >
              <li class="w-fit">
                <.theme_toggle />
              </li>
              <%= if @current_scope do %>
                <li>
                  <span class="font-semibold">{@current_scope.user.email}</span>
                </li>
                <li>
                  <.link href={~p"/rooms/#{@current_scope.user.id}"}>My room</.link>
                </li>
                <li>
                  <.link href={~p"/bitmex_settings"}>API Keys</.link>
                </li>
                <li>
                  <.link href={~p"/users/settings"}>Settings</.link>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete">Log out</.link>
                </li>
              <% else %>
                <li>
                  <.link href={~p"/users/register"}>Register</.link>
                </li>
                <li>
                  <.link href={~p"/users/log-in"}>Log in</.link>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>
    </header>

    <main class="px-4 py-8 sm:px-6 lg:px-8">
      <div class={if @wide, do: "space-y-4", else: "mx-auto max-w-2xl space-y-4"}>
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="flex items-center rounded-full bg-base-200">
      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="relative w-5 h-5 rounded-full transition-colors [[data-theme=light]_&]:bg-base-100 [[data-theme=light]_&]:shadow"
      >
        <.icon name="hero-sun-micro" class="absolute top-1 left-1 w-3 h-3" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="relative w-5 h-5 rounded-full transition-colors [[data-theme=dark]_&]:bg-base-100 [[data-theme=dark]_&]:shadow"
      >
        <.icon name="hero-moon-micro" class="absolute top-1 left-1 w-3 h-3" />
      </button>
    </div>
    """
  end
end
