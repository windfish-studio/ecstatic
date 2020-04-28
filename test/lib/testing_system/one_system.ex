defmodule Test.TestingSystem.OneSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.{OneComponent, AnotherOneComponent}
  use Ecstatic.System

  @impl true
  def aspect do
    Test.TestingAspect.NonReactive.OneSecInfinity
  end

  @impl true
  def dispatch(entity, _changes, delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, OneComponent)
        |> OneComponent.inc()
        |> OneComponent.frequency(delta)
    changes = %Changes{updated: [{Entity.find_component(entity,OneComponent), c}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c]}
  end
end
