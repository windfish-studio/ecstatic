defmodule TickerTest do
  @moduledoc false
  """
  The purpose of this test is to probe what a system is receiving from the watcher
  """
  use ExUnit.Case, async: false
  alias Test.TestingWatcher.{OneSecInfinity, OneSecFiveShots}
  alias Test.TestingComponent
  alias Ecstatic.{Ticker, Changes, Entity, Component}

  @moduletag :capture_log

  doctest Ticker

  setup context do
    {entity_id, component, pids} = TestHelper.initialize(context[:watcher])
    [entity_id: entity_id, component: component]
  end
  
  def periodic_assertions_reception(n, entity_id, time_out) do
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: n, another_var: :zero}, type: TestingComponent}]}},time_out
  end

#  defmacro loop(iterations,entity_id) do
#    Enum.each(iterations, fn i -> assertions(i,entity_id) end)
#  end

  @tag watcher: OneSecInfinity
  test "1 tick per second system", context do
    {entity_id, component} = {context.entity_id, context.component}
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},500
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}]}},2000
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}]}},3000
  end

  @tag watcher: OneSecInfinity
  test "n ticks", context do
    {entity_id, component} = {context.entity_id, context.component}
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},50
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}]}},2000
    assert_receive {%Entity{id: ^entity_id},
                     %Changes{updated: [%Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}]}},1100
  end
  @tag watcher: OneSecFiveShots
  test "limited ticks", context do
    {entity_id, component} = {context.entity_id, context.component}
    assert_receive {%Entity{id: ^entity_id},
                   %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},50
  end
end
