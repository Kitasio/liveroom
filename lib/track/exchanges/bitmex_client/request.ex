defmodule Track.Exchanges.BitmexClient.Request do
  require Logger
  alias Track.Exchanges.BitmexClient.Request

  @moduledoc """
  Provides a struct and functions to build and send authenticated requests to the BitMEX API.

  This module encapsulates the logic for creating a request, signing it with API
  credentials, and handling the response. It uses `Req` for making HTTP requests.

  ## Example Usage

      Request.new()
      |> Request.set_api_key("your-api-key")
      |> Request.set_api_secret("your-api-secret")
      |> Request.set_method(:get)
      |> Request.set_url("https://testnet.bitmex.com/api/v1/user")
      |> Request.send()
  """

  defstruct api_key: nil,
            api_secret: nil,
            method: nil,
            url: nil,
            body: nil,
            headers: nil

  @typedoc """
  Represents a BitMEX API request.
  - `api_key`: The API key.
  - `api_secret`: The API secret.
  - `method`: The HTTP method (e.g., `:get`, `:post`).
  - `url`: The full request URL.
  - `body`: The request body as a JSON-encoded string.
  - `headers`: A list of HTTP headers.
  """
  @type t :: %Request{
          api_key: String.t() | nil,
          api_secret: String.t() | nil,
          method: atom() | nil,
          url: String.t() | nil,
          body: String.t() | nil,
          headers: list() | nil
        }

  @doc """
  Creates a new `t:t/0` struct.

  Optionally accepts a map of attributes to initialize the struct.

  ## Examples

      iex> alias Track.Exchanges.BitmexClient.Request
      iex> request = Request.new()
      iex> is_struct(request, Request)
      true
  """
  @spec new(map()) :: t()
  def new(attrs \\ %{}) when is_map(attrs) do
    struct(Request, attrs)
  end

  @doc """
  Sets the API key for the request.
  """
  def set_api_key(%Request{} = req, api_key) when is_binary(api_key),
    do: %Request{req | api_key: api_key}

  @doc """
  Sets the API secret for the request.
  """
  def set_api_secret(%Request{} = req, api_secret) when is_binary(api_secret),
    do: %Request{req | api_secret: api_secret}

  @doc """
  Sets the HTTP method for the request.

  Allowed methods are `:get`, `:post`, `:put`, `:patch`, and `:delete`.
  """
  def set_method(%Request{} = req, method) when method in [:get, :post, :put, :patch, :delete],
    do: %Request{req | method: method}

  @doc """
  Sets and JSON-encodes the request body from a map.
  """
  def set_and_encode_body(%Request{} = req, body) when is_map(body) do
    %Request{req | body: Jason.encode!(body)}
  end

  @doc """
  Sets the URL for the request.
  """
  def set_url(%Request{} = req, url) when is_binary(url) do
    %Request{req | url: url}
  end

  @doc """
  Validates and sends the request.

  It returns `{:ok, decoded_body}` on success, or `{:error, reason}` if the request
  is invalid or the HTTP request fails.
  """
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
    response =
      req
      |> create_headers()
      |> send_request()

    if response.status in 200..299 do
      {:ok, decode_result(response.body)}
    else
      {:error, {:http_error, response.status}}
    end
  end

  @doc """
  Validates that the `t:t/0` struct has all required fields.

  The required fields are `:api_key`, `:api_secret`, `:method`, and `:url`.
  """
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
