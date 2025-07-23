defmodule Track.Exchanges.BitmexClient.Request do
  require Logger
  alias Track.Exchanges.BitmexClient.Request

  defstruct api_key: nil,
            api_secret: nil,
            method: nil,
            path: nil,
            full_url: nil,
            query: nil,
            body: nil,
            headers: nil

  @type t :: %Request{
          api_key: String.t() | nil,
          api_secret: String.t() | nil,
          method: String.t() | nil,
          path: String.t() | nil,
          full_url: String.t() | nil,
          query: map() | nil,
          body: map() | nil,
          headers: list() | nil
        }

  @base_url "https://testnet.bitmex.com"

  @spec new(map()) :: t()
  def new(attrs \\ %{}) when is_map(attrs) do
    struct(Request, attrs)
  end

  def send(%Request{} = request) do
    with {:ok, req} <- validate_request(request) do
      process_request(req)
    else
      {:error, reason} ->
        Logger.error(reason, label: "Failed to send request")
        {:error, reason}
    end
  end

  defp process_request(%Request{} = req) do
    req
    |> encode_body()
    |> encode_query()
    |> create_full_url()
    |> create_headers()
    |> send_request()
    |> Map.get(:body)
    |> decode_result()
  end

  defp validate_request(%Request{api_key: nil}), do: {:error, :missing_api_key}
  defp validate_request(req), do: {:ok, req}

  defp encode_body(%Request{} = req) do
    if req.method in [:post, :put], do: %Request{req | body: Jason.encode!(req.body)}, else: req
  end

  defp encode_query(%Request{} = req), do: %Request{req | query: URI.encode_query(req.query)}

  defp create_full_url(%Request{} = req) do
    url = (@base_url <> req.path) |> append_query(req.query)

    %Request{req | full_url: url}
  end

  defp append_query(url, query) do
    if query,
      do: "#{url}?#{query}",
      else: url
  end

  defp create_headers(%Request{} = req) do
    expires = :os.system_time(:second) + 60

    headers = [
      {"api-key", req.api_key},
      {"api-expires", Integer.to_string(expires)},
      {"api-signature", sign_request(req, expires)},
      {"content-type", "application/json"}
    ]

    %Request{req | headers: headers}
  end

  defp send_request(%Request{} = req) do
    Req.request!(
      method: req.method,
      url: req.full_url,
      headers: req.headers,
      body: req.body
    )
  end

  defp decode_result(body) when is_binary(body), do: Jason.decode!(body)
  defp decode_result(body), do: body

  defp sign_request(%Request{} = req, expires) do
    data =
      "#{req.method |> to_string() |> String.upcase()}#{append_query(req.path, req.query)}#{expires}#{req.body}"

    :crypto.mac(:hmac, :sha256, req.api_secret, data)
    |> Base.encode16(case: :lower)
  end
end
