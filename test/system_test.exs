defmodule SystemTest do
  use ExUnit.Case, async: false
  alias Test.{TestingSystem, TestingComponent}
  alias Test.TestingWatcher.{OneSecInfinity}
  alias Ecstatic.{Changes, Entity, Component}

  @moduletag :capture_log

  doctest TestingSystem

  setup context do
    {entity_id, components, _pids} = TestHelper.initialize(context[:watchers])
    [entity_id: entity_id, components: components]
  end

  @tag watchers: [OneSecInfinity]
  test "check changes structure", context do
    {entity_id, _components} = {context.entity_id, context.components}
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
                     %Changes{updated: [
                        {%Component{state: %{var: 0, another_var: :zero}, type: TestingComponent},
                          %Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}}
                     ]}}},500
  end
end
