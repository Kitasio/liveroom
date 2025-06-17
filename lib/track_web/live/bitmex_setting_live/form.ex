defmodule TrackWeb.BitmexSettingLive.Form do
  use TrackWeb, :live_view

  alias Track.Exchanges
  alias Track.Exchanges.BitmexSetting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage bitmex_setting records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="bitmex_setting-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:api_key]} type="text" label="Api key" />
        <.input field={@form[:api_secret]} type="text" label="Api secret" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Bitmex setting</.button>
          <.button navigate={return_path(@current_scope, @return_to, @bitmex_setting)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    bitmex_setting = Exchanges.get_bitmex_setting!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Bitmex setting")
    |> assign(:bitmex_setting, bitmex_setting)
    |> assign(:form, to_form(Exchanges.change_bitmex_setting(socket.assigns.current_scope, bitmex_setting)))
  end

  defp apply_action(socket, :new, _params) do
    bitmex_setting = %BitmexSetting{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Bitmex setting")
    |> assign(:bitmex_setting, bitmex_setting)
    |> assign(:form, to_form(Exchanges.change_bitmex_setting(socket.assigns.current_scope, bitmex_setting)))
  end

  @impl true
  def handle_event("validate", %{"bitmex_setting" => bitmex_setting_params}, socket) do
    changeset = Exchanges.change_bitmex_setting(socket.assigns.current_scope, socket.assigns.bitmex_setting, bitmex_setting_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"bitmex_setting" => bitmex_setting_params}, socket) do
    save_bitmex_setting(socket, socket.assigns.live_action, bitmex_setting_params)
  end

  defp save_bitmex_setting(socket, :edit, bitmex_setting_params) do
    case Exchanges.update_bitmex_setting(socket.assigns.current_scope, socket.assigns.bitmex_setting, bitmex_setting_params) do
      {:ok, bitmex_setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Bitmex setting updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, bitmex_setting)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bitmex_setting(socket, :new, bitmex_setting_params) do
    case Exchanges.create_bitmex_setting(socket.assigns.current_scope, bitmex_setting_params) do
      {:ok, bitmex_setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Bitmex setting created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, bitmex_setting)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _bitmex_setting), do: ~p"/bitmex_settings"
  defp return_path(_scope, "show", bitmex_setting), do: ~p"/bitmex_settings/#{bitmex_setting}"
end
