defmodule ComponentTest do
  use ExUnit.Case, async: false
  alias Test.TestingComponent.OneComponent
  alias Ecstatic.Component

  @moduletag :capture_log

  doctest Component

  test "module exists" do
    assert is_list(OneComponent.module_info())
  end

  test "module exists basic" do
    assert is_list(Component.module_info())
  end

  test "create default component" do
    new_comp = Component.new(Component,%{})
    assert TestHelper.ecs_id?(new_comp.id)
    assert new_comp.state == %{}
    assert new_comp.type == Component
  end

  test "instance a new component" do
    new_comp = OneComponent.new()
    assert TestHelper.ecs_id?(new_comp.id)
    assert new_comp.state == %{var: 0, f: 0}
    assert new_comp.type == OneComponent
  end

  test "init component's state" do
    new_comp = OneComponent.new(%{var: 42, f: 0, robot: Depressed})
    assert TestHelper.ecs_id?(new_comp.id)
    assert new_comp.state == %{var: 42, f: 0, robot: Depressed}
    assert new_comp.type == OneComponent
  end
end
