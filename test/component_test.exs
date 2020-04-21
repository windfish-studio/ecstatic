defmodule ComponentTest do
  use ExUnit.Case
  alias Test.TestingComponent
  alias Ecstatic.Component

  @moduletag :capture_log

  doctest Component

  test "module exists" do
    assert is_list(TestingComponent.module_info())
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
    new_comp = TestingComponent.new()
    assert TestHelper.ecs_id?(new_comp.id)
    assert new_comp.state == %{var: 0, another_var: :zero}
    assert new_comp.type == TestingComponent
  end

  test "init component's state" do
    new_comp = TestingComponent.new(%{var: 42, another_var: :fortytwo, robot: Depressed})
    assert TestHelper.ecs_id?(new_comp.id)
    assert new_comp.state == %{var: 42, another_var: :fortytwo, robot: Depressed}
    assert new_comp.type == TestingComponent
  end
end
