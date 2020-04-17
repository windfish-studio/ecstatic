defmodule SystemTest do
  use ExUnit.Case

  alias Test.{TestingWatcher, TestingSystem}
  alias Ecstatic.{Changes, System, Store.Ets, Entity}

  @moduletag :capture_log

  doctest TestingSystem

  setup do
    Application.put_env(:ecstatic, :watchers, fn() -> TestingWatcher.watchers end)
    Application.put_env(:ecstatic, :test_pid, self())
    {:ok, _pid} = Ecstatic.Supervisor.start_link([])
    TestHelper.initialize()
    :ok
  end

#  setup do
#    Application.put_env(:ecstatic, :debug_pid, self())
#  end

  test "module exists" do
    assert is_list(System.module_info())
  end

  test "test initialization" do
    {entityId, component} = TestHelper.initialize()
    entity = Ets.get_entity(entityId)
    assert TestHelper.ecs_id?(entity.id)
    assert Entity.has_component?(entity, Test.TestingComponent)
    component = Entity.find_component(entity,Test.TestingComponent)
    assert component.state.var == 0
    assert component.state.another_var == :zero
  end

  test "system" do
    message = receive do
      message -> message
      after
        1000 -> :timeout
    end
    assert message == "hello world"
  end
end
