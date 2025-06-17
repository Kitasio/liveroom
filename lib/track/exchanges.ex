defmodule Track.Exchanges do
  @moduledoc """
  The Exchanges context.
  """

  import Ecto.Query, warn: false
  alias Track.Repo

  alias Track.Exchanges.BitmexSetting
  alias Track.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any bitmex_setting changes.

  The broadcasted messages match the pattern:

    * {:created, %BitmexSetting{}}
    * {:updated, %BitmexSetting{}}
    * {:deleted, %BitmexSetting{}}

  """
  def subscribe_bitmex_settings(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Track.PubSub, "user:#{key}:bitmex_settings")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Track.PubSub, "user:#{key}:bitmex_settings", message)
  end

  @doc """
  Returns the list of bitmex_settings.

  ## Examples

      iex> list_bitmex_settings(scope)
      [%BitmexSetting{}, ...]

  """
  def list_bitmex_settings(%Scope{} = scope) do
    Repo.all(
      from bitmex_setting in BitmexSetting, where: bitmex_setting.user_id == ^scope.user.id
    )
  end

  @doc """
  Gets a single bitmex_setting.

  Raises `Ecto.NoResultsError` if the Bitmex setting does not exist.

  ## Examples

      iex> get_bitmex_setting!(123)
      %BitmexSetting{}

      iex> get_bitmex_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bitmex_setting!(%Scope{} = scope, id) do
    Repo.get_by!(BitmexSetting, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets the latest bitmex_setting for the given user.

  Raises `Ecto.NoResultsError` if the Bitmex setting does not exist.

  ## Examples

      iex> get_latest_bitmex_setting!(scope)
      %BitmexSetting{}

      iex> get_latest_bitmex_setting!(scope)
      ** (Ecto.NoResultsError)
  """
  def get_latest_bitmex_setting!(%Scope{} = scope) do
    Repo.one!(
      from bitmex_setting in BitmexSetting,
        where: bitmex_setting.user_id == ^scope.user.id,
        order_by: [desc: bitmex_setting.inserted_at],
        limit: 1
    )
  end

  @doc """
  Creates a bitmex_setting.

  ## Examples

      iex> create_bitmex_setting(%{field: value})
      {:ok, %BitmexSetting{}}

      iex> create_bitmex_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bitmex_setting(%Scope{} = scope, attrs) do
    with {:ok, bitmex_setting = %BitmexSetting{}} <-
           %BitmexSetting{}
           |> BitmexSetting.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, bitmex_setting})
      {:ok, bitmex_setting}
    end
  end

  @doc """
  Updates a bitmex_setting.

  ## Examples

      iex> update_bitmex_setting(bitmex_setting, %{field: new_value})
      {:ok, %BitmexSetting{}}

      iex> update_bitmex_setting(bitmex_setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bitmex_setting(%Scope{} = scope, %BitmexSetting{} = bitmex_setting, attrs) do
    true = bitmex_setting.user_id == scope.user.id

    with {:ok, bitmex_setting = %BitmexSetting{}} <-
           bitmex_setting
           |> BitmexSetting.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, bitmex_setting})
      {:ok, bitmex_setting}
    end
  end

  @doc """
  Deletes a bitmex_setting.

  ## Examples

      iex> delete_bitmex_setting(bitmex_setting)
      {:ok, %BitmexSetting{}}

      iex> delete_bitmex_setting(bitmex_setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bitmex_setting(%Scope{} = scope, %BitmexSetting{} = bitmex_setting) do
    true = bitmex_setting.user_id == scope.user.id

    with {:ok, bitmex_setting = %BitmexSetting{}} <-
           Repo.delete(bitmex_setting) do
      broadcast(scope, {:deleted, bitmex_setting})
      {:ok, bitmex_setting}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bitmex_setting changes.

  ## Examples

      iex> change_bitmex_setting(bitmex_setting)
      %Ecto.Changeset{data: %BitmexSetting{}}

  """
  def change_bitmex_setting(%Scope{} = scope, %BitmexSetting{} = bitmex_setting, attrs \\ %{}) do
    true = bitmex_setting.user_id == scope.user.id

    BitmexSetting.changeset(bitmex_setting, attrs, scope)
  end
end
