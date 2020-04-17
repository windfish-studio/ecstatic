defmodule EntityTest do
  use ExUnit.Case

  alias Ecstatic.{Entity, Component, Aspect}
  alias Test.{TestingEntity,TestingComponent}
  alias TestHelper

  @moduletag :capture_log

  doctest Entity

  setup do
#    Application.put_env(:ecstatic, :watchers, fn() -> TestingWatcher.watchers end)
    {:ok, _pid} = Ecstatic.Supervisor.start_link([])
    :ok
  end

  test "default module exists" do
    assert is_list(Entity.module_info())
  end

  test "module exists" do
    assert is_list(TestingEntity.module_info())
  end

  test "create default TestingEntity" do
    entity = TestingEntity.new([])
    assert TestHelper.ecs_id?(entity.id)
    assert entity.components == []
  end

  test "create default 2 TestingEntity" do
    entity = TestingEntity.new()
    assert TestHelper.ecs_id?(entity.id)
    assert entity.components == []
  end

  test "create Entity with a component" do
    component = TestingComponent.new()
    entity = TestingEntity.new([component])
    assert TestHelper.ecs_id?(entity.id)
    TestHelper.wait_receiver()
    entity = Ecstatic.Store.Ets.get_entity(entity.id)
    assert entity.components == [component]
  end

  test "adding component" do
    component = TestingComponent.new()
    entity = TestingEntity.new()
    |> Entity.add(component)
    TestHelper.wait_receiver()
    entity = Ecstatic.Store.Ets.get_entity(entity.id)
    assert TestHelper.ecs_id?(entity.id)
    assert entity.components == [component]
  end

  test "match aspect" do
    aspect = Aspect.new(with: [TestingComponent], without: [])
    assert aspect == %Aspect{with: [TestingComponent], without: []} #TODO: move this assert to aspectTest
    entity = TestingEntity.new([TestingComponent.new])
    TestHelper.wait_receiver()
    entity = Ecstatic.Store.Ets.get_entity(entity.id)
    assert Entity.match_aspect?(entity, aspect)
  end

  test "has component" do
    component = TestingComponent.new()
    entity = TestingEntity.new()
    assert !Entity.has_component?(entity,TestingComponent)
    entity = Entity.add(entity, component)
    TestHelper.wait_receiver()
    entity = Ecstatic.Store.Ets.get_entity(entity.id)
    assert Entity.has_component?(entity,TestingComponent)
  end


end