defmodule SystemTest do
  use ExUnit.Case, async: false
  alias Test.{TestingWatcher, TestingSystem, TestingComponent}
  alias Test.TestingWatcher.{OneSecInfinity, Dead}
  alias Ecstatic.{Changes, System, Store.Ets, Entity, Component}

  @moduletag :capture_log

  doctest TestingSystem

  setup context do
    {entity_id, component, pids} = TestHelper.initialize(context[:watchers])
    [entity_id: entity_id, component: component]
  end

  @tag watchers: [OneSecInfinity]
  test "test initialization", context do
    {entity_id, component} = {context.entity_id, context.component}
    assert_receive {%Entity{id: ^entity_id},
           %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},50
  end
end
