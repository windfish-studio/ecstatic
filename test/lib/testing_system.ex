defmodule Test.TestingSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent
  use Ecstatic.System

  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end
  #non-reactive
  def dispatch(entity) do
    pid = Application.get_env(:ecstatic, :test_pid)
    send pid, "hello world"
#    c = Entity.find_component(entity, TestingComponent)
    %Changes{updated: [Test.TestingComponent.new()]}
  end
  #reactive
  def dispatch(entity,changes) do
    nil
  end
end
