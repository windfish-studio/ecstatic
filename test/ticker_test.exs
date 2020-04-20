defmodule TickerTest do
  use ExUnit.Case

  alias Ticker

  @moduletag :capture_log

  doctest Ticker

  setup do
    Application.put_env(:ecstatic, :watchers, fn() -> TestingWatcher.watchers end)
    Application.put_env(:ecstatic, :test_pid, self())
    {:ok, _pid} = Ecstatic.Supervisor.start_link([])
    TestHelper.initialize()
    :ok
  end

  test "module exists" do
    assert is_list(Ticker.module_info())
  end

  test "1 sec watcher" do
    t = Ticker.last_tick_time
    TestHelper.wait_receiver(1200)
    assert Ticker.last_tick_time
  end
end
