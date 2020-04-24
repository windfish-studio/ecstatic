defmodule Test.TestingSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent
  use Ecstatic.System
  require Logger
  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end

  def dispatch(entity, _changes, delta) do
    Logger.debug(inspect("TestingSystem.dispatch running"))
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, TestingComponent)
        |> TestingComponent.inc()
        |> TestingComponent.frequency(delta)
    changes = %Changes{updated: [{Entity.find_component(entity,TestingComponent), c}]}
    send pid, {:testing_system, {entity, changes}}
    %Changes{updated: [c]}
  end
end
