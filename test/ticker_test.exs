defmodule TickerTest do
  use ExUnit.Case
  alias Test.TestingWatcher
  alias Ecstatic.Ticker

  @moduletag :capture_log

  doctest Ticker

  setup do
    :ok
  end

  test "module exists" do
    TestHelper.initialize([TestingWatcher])
    assert is_list(Ticker.module_info())
  end

  test "1 sec watcher" do
    TestHelper.initialize([TestingWatcher])
    assert_receive "hello world",1000
  end

  test "infinity watcher" do
    TestHelper.initialize([TestingWatcher])
  end

  test "n ticks" do
    assert_receive n
    refute_receive :bye, 1000
  end
end
