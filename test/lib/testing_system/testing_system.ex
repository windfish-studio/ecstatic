defmodule Test.TestingSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent
  use Ecstatic.System

  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end
  def dispatch(entity, delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, TestingComponent)
        |> TestingComponent.inc()
        |> TestingComponent.frequency(delta)
    changes = %Changes{updated: [{Entity.find_component(entity,TestingComponent), c}]}
    send pid, {:testing_system, {entity, changes}}
    %Changes{updated: [c]}
  end
  #reactive
  def dispatch(entity,changes,delta) do
    nil
  end

  def process(_,_) do
    :ok
  end

end
