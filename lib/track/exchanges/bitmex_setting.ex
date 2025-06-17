defmodule Track.Exchanges.BitmexSetting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bitmex_settings" do
    field :api_key, :string
    field :api_secret, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bitmex_setting, attrs, user_scope) do
    bitmex_setting
    |> cast(attrs, [:api_key, :api_secret])
    |> validate_required([:api_key, :api_secret])
    |> put_change(:user_id, user_scope.user.id)
  end
end
