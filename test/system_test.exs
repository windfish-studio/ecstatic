defmodule SystemTest do
  use ExUnit.Case
  alias Test.{TestingWatcher, TestingSystem, TestingComponent}
  alias Test.TestingWatcher.{OneSecInfinity, Dead}
  alias Ecstatic.{Changes, System, Store.Ets, Entity, Component}

  @moduletag :capture_log

  doctest TestingSystem

  setup do
    :ok
  end

  test "module exists" do
    assert is_list(System.module_info())
  end

  test "test initialization" do
    {entityId, component} = TestHelper.initialize(OneSecInfinity)
    assert_receive {%Entity{id: ^entityId},
           %Changes{updated: [%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}]}},50
  end
end
