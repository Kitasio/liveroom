defmodule Track.ExchangesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Track.Exchanges` context.
  """

  @doc """
  Generate a bitmex_setting.
  """
  def bitmex_setting_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        api_key: "some api_key",
        api_secret: "some api_secret"
      })

    {:ok, bitmex_setting} = Track.Exchanges.create_bitmex_setting(scope, attrs)
    bitmex_setting
  end
end
