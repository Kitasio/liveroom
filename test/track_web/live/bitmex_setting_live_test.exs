defmodule TrackWeb.BitmexSettingLiveTest do
  use TrackWeb.ConnCase

  import Phoenix.LiveViewTest
  import Track.ExchangesFixtures

  @create_attrs %{api_key: "some api_key", api_secret: "some api_secret"}
  @update_attrs %{api_key: "some updated api_key", api_secret: "some updated api_secret"}
  @invalid_attrs %{api_key: nil, api_secret: nil}

  setup :register_and_log_in_user

  defp create_bitmex_setting(%{scope: scope}) do
    bitmex_setting = bitmex_setting_fixture(scope)

    %{bitmex_setting: bitmex_setting}
  end

  describe "Index" do
    setup [:create_bitmex_setting]

    test "lists all bitmex_settings", %{conn: conn, bitmex_setting: bitmex_setting} do
      {:ok, _index_live, html} = live(conn, ~p"/bitmex_settings")

      assert html =~ "Listing Bitmex settings"
      assert html =~ bitmex_setting.api_key
    end

    test "saves new bitmex_setting", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/bitmex_settings")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Bitmex setting")
               |> render_click()
               |> follow_redirect(conn, ~p"/bitmex_settings/new")

      assert render(form_live) =~ "New Bitmex setting"

      assert form_live
             |> form("#bitmex_setting-form", bitmex_setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#bitmex_setting-form", bitmex_setting: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/bitmex_settings")

      html = render(index_live)
      assert html =~ "Bitmex setting created successfully"
      assert html =~ "some api_key"
    end

    test "updates bitmex_setting in listing", %{conn: conn, bitmex_setting: bitmex_setting} do
      {:ok, index_live, _html} = live(conn, ~p"/bitmex_settings")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#bitmex_settings-#{bitmex_setting.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/bitmex_settings/#{bitmex_setting}/edit")

      assert render(form_live) =~ "Edit Bitmex setting"

      assert form_live
             |> form("#bitmex_setting-form", bitmex_setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#bitmex_setting-form", bitmex_setting: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/bitmex_settings")

      html = render(index_live)
      assert html =~ "Bitmex setting updated successfully"
      assert html =~ "some updated api_key"
    end

    test "deletes bitmex_setting in listing", %{conn: conn, bitmex_setting: bitmex_setting} do
      {:ok, index_live, _html} = live(conn, ~p"/bitmex_settings")

      assert index_live |> element("#bitmex_settings-#{bitmex_setting.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#bitmex_settings-#{bitmex_setting.id}")
    end
  end

  describe "Show" do
    setup [:create_bitmex_setting]

    test "displays bitmex_setting", %{conn: conn, bitmex_setting: bitmex_setting} do
      {:ok, _show_live, html} = live(conn, ~p"/bitmex_settings/#{bitmex_setting}")

      assert html =~ "Show Bitmex setting"
      assert html =~ bitmex_setting.api_key
    end

    test "updates bitmex_setting and returns to show", %{conn: conn, bitmex_setting: bitmex_setting} do
      {:ok, show_live, _html} = live(conn, ~p"/bitmex_settings/#{bitmex_setting}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/bitmex_settings/#{bitmex_setting}/edit?return_to=show")

      assert render(form_live) =~ "Edit Bitmex setting"

      assert form_live
             |> form("#bitmex_setting-form", bitmex_setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#bitmex_setting-form", bitmex_setting: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/bitmex_settings/#{bitmex_setting}")

      html = render(show_live)
      assert html =~ "Bitmex setting updated successfully"
      assert html =~ "some updated api_key"
    end
  end
end
