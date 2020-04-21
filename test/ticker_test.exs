defmodule TickerTest do
  @moduledoc false
  """
  The purpose of this test is to probe what a system is receiving from the watcher
  """
  use ExUnit.Case
  alias Test.TestingWatcher.{OneSecInfinity, OneSecFiveShots}
  alias Test.TestingComponent
  alias Ecstatic.{Ticker, Changes, Entity, Component}

  @moduletag :capture_log

  doctest Ticker

  setup do
    :ok
  end

  def periodic_assertions_reception(n, entityId, time_out) do
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: n, another_var: :zero}, type: TestingComponent}]}},time_out
  end

#  defmacro loop(iterations,entityId) do
#    Enum.each(iterations, fn i -> assertions(i,entityId) end)
#  end

  test "module exists" do
    TestHelper.initialize(OneSecInfinity)
    assert is_list(Ticker.module_info())
  end

  test "infinity watcher" do
    TestHelper.initialize(OneSecInfinity)
  end

  test "1 tick per second system" do
    {entityId, component} = TestHelper.initialize(OneSecInfinity)
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},500
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}]}},2000
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}]}},3000
  end

  test "n ticks" do
    {entityId, component} = TestHelper.initialize(OneSecInfinity)
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},50
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}]}},2000
    assert_receive {%Entity{id: ^entityId},
                     %Changes{updated: [%Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}]}},1100
  end

  test "limited ticks" do
    {entityId, component} = TestHelper.initialize(OneSecFiveShots)
    assert_receive {%Entity{id: ^entityId},
                   %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},50
  end
end
