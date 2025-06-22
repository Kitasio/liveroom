ExUnit Summary (Elixir's Test Framework)

    Test Files: Use .exs extension for tests.
    Start ExUnit: Call ExUnit.start() (usually in test/test_helper.exs).
    Running Tests: Use mix test.

Test Example

defmodule ExampleTest do
  use ExUnit.Case
  doctest Example
  test "greets the world" do
    assert Example.hello() == :world
  end
end

    Test results show dots (e.g. ..) for test and doctest.

Assertions

    assert expr – Passes if expr is true; otherwise fails the test.
    refute expr – Passes if expr is false.
    assert_raise(Error, fn -> ... end) – Ensures an error is raised.
    assert_receive(val, timeout \\ 100) – Asserts a process received val within an optional timeout.
    assert_received(val) – Asserts a message already in the process mailbox.

Capture Output

    ExUnit.CaptureIO – Capture IO output.
    ExUnit.CaptureLog – Capture logs.

Test Setup

    setup – Runs before each test.
    setup_all – Runs once before all tests.
    Return {:ok, state} from setup; state passed to tests.

Example:

setup_all do
  {:ok, recipient: :world}
end

test "greets", state do
  assert Example.hello() == state[:recipient]
end

Mocks

    Elixir encourages defining explicit behaviors (interfaces), and mock implementations for tests ("mock as noun"), not ad-hoc function stubs ("mock as verb").
    Use dependency injection or application config to swap real modules for mocks.
    For advanced/concurrent mocks, use the Mox library.



Writing Testable Code in Elixir: Key Patterns and Mocks

    Mocks: Simulate function outputs for testing; Elixir supports mocks differently than other languages.
    Dependency Injection: Increase testability by injecting dependencies.
        Instead of hard-coding modules:

def get_username(username), do: HTTPoison.get(...)

Pass module or use apply:

    def get_username(username, http_client), do: http_client.get(...)
    # or
    def get_username(username, http_client), do: apply(http_client, :get, [url])

Application Configuration: Store the module to be used in Application config; allows swapping implementations per environment.

    def get_username(username), do: http_client().get(...)
    defp http_client, do: Application.get_env(:my_app, :http_client)
    # In config: config :my_app, :http_client, HTTPoison

    Dynamic Config Change in Tests: Temporarily override config during tests using Application.put_env/4, then restore after each test.
        Not recommended: can cause race conditions (asynchronous tests interfere), no contract enforcement, and codebase clutter.

Mox: The Recommended Solution for Mocks in Elixir

    Add dependency:

{:mox, "~> 0.5.2", only: :test}

In test_helper.exs define mocks and set config:

Mox.defmock(HTTPoisonMock, for: HTTPoison.Base)
Application.put_env(:my_app, :http_client, HTTPoisonMock)

The for: module must be a @behaviour module with callbacks so Mox can enforce a contract.
In tests (with async: true):

    import Mox
    setup :verify_on_exit!

    test "successful" do
      expect(HTTPoisonMock, :get, fn _ -> {:ok, "result"} end)
      assert {:ok, _} = MyApp.get_username("name")
    end

    test "error" do
      expect(HTTPoisonMock, :get, fn _ -> {:error, "fail"} end)
      assert {:error, _} = MyApp.get_username("bad")
    end

    Benefits of Mox:
        Safe for async tests (per-process).
        Enforces contracts via behaviors.
        No need to define cluttering mock modules.
        Flexible, per-test control of mock behavior.
    Note: If a 3rd-party package lacks a behavior, define your own.

Summary: Use dependency injection (by module argument or app config) + behaviors. Avoid global test config overrides. Use Mox for safe, composable, contract-checked mocks in Elixir tests.
