defmodule Track.ExchangesTest do
  use Track.DataCase

  alias Track.Exchanges

  describe "bitmex_settings" do
    alias Track.Exchanges.BitmexSetting

    import Track.AccountsFixtures, only: [user_scope_fixture: 0]
    import Track.ExchangesFixtures

    @invalid_attrs %{api_key: nil, api_secret: nil}

    test "list_bitmex_settings/1 returns all scoped bitmex_settings" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      other_bitmex_setting = bitmex_setting_fixture(other_scope)
      assert Exchanges.list_bitmex_settings(scope) == [bitmex_setting]
      assert Exchanges.list_bitmex_settings(other_scope) == [other_bitmex_setting]
    end

    test "get_bitmex_setting!/2 returns the bitmex_setting with given id" do
      scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      other_scope = user_scope_fixture()
      assert Exchanges.get_bitmex_setting!(scope, bitmex_setting.id) == bitmex_setting
      assert_raise Ecto.NoResultsError, fn -> Exchanges.get_bitmex_setting!(other_scope, bitmex_setting.id) end
    end

    test "create_bitmex_setting/2 with valid data creates a bitmex_setting" do
      valid_attrs = %{api_key: "some api_key", api_secret: "some api_secret"}
      scope = user_scope_fixture()

      assert {:ok, %BitmexSetting{} = bitmex_setting} = Exchanges.create_bitmex_setting(scope, valid_attrs)
      assert bitmex_setting.api_key == "some api_key"
      assert bitmex_setting.api_secret == "some api_secret"
      assert bitmex_setting.user_id == scope.user.id
    end

    test "create_bitmex_setting/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Exchanges.create_bitmex_setting(scope, @invalid_attrs)
    end

    test "update_bitmex_setting/3 with valid data updates the bitmex_setting" do
      scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      update_attrs = %{api_key: "some updated api_key", api_secret: "some updated api_secret"}

      assert {:ok, %BitmexSetting{} = bitmex_setting} = Exchanges.update_bitmex_setting(scope, bitmex_setting, update_attrs)
      assert bitmex_setting.api_key == "some updated api_key"
      assert bitmex_setting.api_secret == "some updated api_secret"
    end

    test "update_bitmex_setting/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)

      assert_raise MatchError, fn ->
        Exchanges.update_bitmex_setting(other_scope, bitmex_setting, %{})
      end
    end

    test "update_bitmex_setting/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Exchanges.update_bitmex_setting(scope, bitmex_setting, @invalid_attrs)
      assert bitmex_setting == Exchanges.get_bitmex_setting!(scope, bitmex_setting.id)
    end

    test "delete_bitmex_setting/2 deletes the bitmex_setting" do
      scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      assert {:ok, %BitmexSetting{}} = Exchanges.delete_bitmex_setting(scope, bitmex_setting)
      assert_raise Ecto.NoResultsError, fn -> Exchanges.get_bitmex_setting!(scope, bitmex_setting.id) end
    end

    test "delete_bitmex_setting/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      assert_raise MatchError, fn -> Exchanges.delete_bitmex_setting(other_scope, bitmex_setting) end
    end

    test "change_bitmex_setting/2 returns a bitmex_setting changeset" do
      scope = user_scope_fixture()
      bitmex_setting = bitmex_setting_fixture(scope)
      assert %Ecto.Changeset{} = Exchanges.change_bitmex_setting(scope, bitmex_setting)
    end
  end
end
