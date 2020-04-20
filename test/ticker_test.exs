defmodule TickerTest do
  use ExUnit.Case
  alias Test.TestingWatcher
  alias Ecstatic.Ticker

  @moduletag :capture_log

  doctest Ticker

  setup do
    Application.put_env(:ecstatic, :ticker, fn() -> Ticker.last_tick_time end)
    {:ok, _pid} = Ecstatic.Supervisor.start_link([])
    TestHelper.initialize()
    :ok
  end

  test "module exists" do
    assert is_list(Ticker.module_info())
  end

  test "1 sec watcher" do
    message = receive do
      message -> message
    after
      1000 -> :timeout
    end
    assert message == "hello world"
    assert_receive "hello world"
  end
end
