defmodule Track.Exchanges.BitmexClient.RequestTest do
  use ExUnit.Case
  alias Track.Exchanges.BitmexClient.Request

  @sample_request Request.new(%{
                    api_key: "123123",
                    api_secret: "123123",
                    method: :get,
                    url: "https://example.com",
                    body: nil,
                    headers: nil
                  })

  describe "request validation" do
    test "empty api_key returns an error" do
      req_without_api_key = %Request{@sample_request | api_key: nil}
      assert Request.validate_request(req_without_api_key) == {:error, :missing_api_key}
    end

    test "empty api_secret returns an error" do
      req_without_api_key = %Request{@sample_request | api_secret: nil}
      assert Request.validate_request(req_without_api_key) == {:error, :missing_api_secret}
    end

    test "empty method returns an error" do
      req_without_method = %Request{@sample_request | method: nil}
      assert Request.validate_request(req_without_method) == {:error, :missing_method}
    end

    test "empty url returns an error" do
      req_without_url = %Request{@sample_request | url: nil}
      assert Request.validate_request(req_without_url) == {:error, :missing_url}
    end
  end

  describe "setters" do
    test "set api key sucessfully" do
      valid_api_key = "123123"

      req = Request.new() |> Request.set_api_key(valid_api_key)

      assert req.api_key == valid_api_key
    end

    test "set invalid api key" do
      invalid_api_key = 123

      assert_raise FunctionClauseError, fn ->
        Request.new() |> Request.set_api_key(invalid_api_key)
      end
    end

    test "set api secret sucessfully" do
      valid_secret = "123123"

      req = Request.new() |> Request.set_api_secret(valid_secret)

      assert req.api_secret == valid_secret
    end

    test "set invalid api secret" do
      invalid_api_secret = 123

      assert_raise FunctionClauseError, fn ->
        Request.new() |> Request.set_api_secret(invalid_api_secret)
      end
    end

    test "set method successfully" do
      valid_method = :get

      req = Request.new() |> Request.set_method(valid_method)

      assert req.method == valid_method
    end

    test "set invalid method" do
      invalid_method = :head

      assert_raise FunctionClauseError, fn ->
        Request.new() |> Request.set_method(invalid_method)
      end
    end

    test "set and encode body successfully" do
      valid_body = %{"key" => "value"}
      encoded_body = Jason.encode!(valid_body)

      req = Request.new() |> Request.set_and_encode_body(valid_body)

      assert req.body == encoded_body
    end

    test "set and encode invalid body" do
      invalid_body = "a string, not a map"

      assert_raise FunctionClauseError, fn ->
        Request.new() |> Request.set_and_encode_body(invalid_body)
      end
    end

    test "set url successfully" do
      valid_url = "https://test.com"
      req = Request.new() |> Request.set_url(valid_url)
      assert req.url == valid_url
    end

    test "set invalid url" do
      invalid_url = 123

      assert_raise FunctionClauseError, fn ->
        Request.new() |> Request.set_url(invalid_url)
      end
    end
  end
end
