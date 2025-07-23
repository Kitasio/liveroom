defmodule Track.Exchanges.BitmexClient.APIImpl do
  alias Track.Exchanges
  alias Track.Accounts.Scope
  alias Track.Exchanges.BitmexClient.Request

  @behaviour Track.Exchanges.BitmexClient.API

  @impl true
  def get_balance(%Scope{} = scope, currency) do
    bitmex_settings = Exchanges.get_latest_bitmex_setting!(scope)

    request_params = %{
      api_key: bitmex_settings.api_key,
      api_secret: bitmex_settings.api_secret,
      method: :get,
      path: "/api/v1/user/margin",
      body: nil,
      query: %{"currency" => currency}
    }

    result = request_params |> Request.new() |> Request.send()

    {:ok, result}
  end
end
