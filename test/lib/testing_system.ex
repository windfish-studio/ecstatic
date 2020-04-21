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
    #I can only test delta, not the ticks. Also, i can see components, changes, entity
    c = Entity.find_component(entity, TestingComponent)
    |> TestingComponent.inc()
    changes = %Changes{updated: [c]}
    send pid, {entity, changes}
    changes
  end
  #reactive
  def dispatch(entity,changes,delta) do
    nil
  end

  def process(_,_) do
    :ok
  end

end
