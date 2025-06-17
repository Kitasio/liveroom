defmodule Track.Repo.Migrations.CreateBitmexSettings do
  use Ecto.Migration

  def change do
    create table(:bitmex_settings) do
      add :api_key, :string
      add :api_secret, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:bitmex_settings, [:user_id])
  end
end
