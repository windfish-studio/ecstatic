defmodule EntityTest do
  use ExUnit.Case, async: false
  alias Ecstatic.{Entity, Component, Aspect, Changes}
  alias Test.{TestingEntity,TestingComponent}
  alias TestHelper

  @moduletag :capture_log

  doctest Entity

  setup do
    {:ok, _pids} = TestHelper.start_supervisor_with_monitor()
    :ok
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

  test "find component" do
    component = TestingComponent.new()
    entity = TestingEntity.new([component])
    assert Entity.find_component(entity,TestingComponent) == nil
    TestHelper.wait_receiver()
    entity = Ecstatic.Store.Ets.get_entity(entity.id)
    assert Entity.find_component(entity,TestingComponent) == component
  end

  test "apply_changes" do
    component = TestingComponent.new()
    entity = TestingEntity.new([component])
    new_state = %{component.state | var: 42}
    new_component = %{component | state: new_state}
    entity = Entity.apply_changes(entity, %Changes{updated: [{component,new_component}]})
    TestHelper.wait_receiver()
    assert entity.components == [new_component]
  end
end
