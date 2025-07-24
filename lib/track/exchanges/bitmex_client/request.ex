defmodule Track.Exchanges.BitmexClient.Request do
  require Logger
  alias Track.Exchanges.BitmexClient.Request

  defstruct api_key: nil,
            api_secret: nil,
            method: nil,
            url: nil,
            body: nil,
            headers: nil

  @type t :: %Request{
          api_key: String.t() | nil,
          api_secret: String.t() | nil,
          method: String.t() | nil,
          url: String.t() | nil,
          body: String.t() | nil,
          headers: list() | nil
        }

  @spec new(map()) :: t()
  def new(attrs \\ %{}) when is_map(attrs) do
    struct(Request, attrs)
  end

  def set_api_key(%Request{} = req, api_key) when is_binary(api_key),
    do: %Request{req | api_key: api_key}

  def set_api_secret(%Request{} = req, api_secret) when is_binary(api_secret),
    do: %Request{req | api_secret: api_secret}

  def set_method(%Request{} = req, method) when method in [:get, :post, :put, :patch, :delete],
    do: %Request{req | method: method}

  def set_and_encode_body(%Request{} = req, body) when is_map(body) do
    %Request{req | body: Jason.encode!(body)}
  end

  def set_url(%Request{} = req, url) when is_binary(url) do
    %Request{req | url: url}
  end

  def send(%Request{} = request) do
    with {:ok, req} <- validate_request(request) do
      try do
        {:ok, process_request(req)}
      rescue
        e ->
          Logger.error(Exception.format(:error, e, __STACKTRACE__),
            label: "Failed to send request"
          )

          {:error, e}
      end
    else
      {:error, reason} ->
        Logger.error(reason, label: "Failed to send request")
        {:error, reason}
    end
  end

  defp process_request(%Request{} = req) do
    req
    |> create_headers()
    |> send_request()
    |> Map.get(:body)
    |> decode_result()
  end

  def validate_request(%Request{api_key: nil}), do: {:error, :missing_api_key}
  def validate_request(%Request{api_secret: nil}), do: {:error, :missing_api_secret}
  def validate_request(%Request{method: nil}), do: {:error, :missing_method}
  def validate_request(%Request{url: nil}), do: {:error, :missing_url}
  def validate_request(req), do: {:ok, req}

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
      url: req.url,
      headers: req.headers,
      body: req.body
    )
  end

  defp decode_result(body) when is_binary(body), do: Jason.decode!(body)
  defp decode_result(body), do: body

  defp append_query(url, query) do
    if query,
      do: "#{url}?#{query}",
      else: url
  end

  defp sign_request(%Request{} = req, expires) do
    parsed_url = URI.parse(req.url)

    data =
      "#{req.method |> to_string() |> String.upcase()}#{append_query(parsed_url.path, parsed_url.query)}#{expires}#{req.body}"

    :crypto.mac(:hmac, :sha256, req.api_secret, data)
    |> Base.encode16(case: :lower)
  end
end
