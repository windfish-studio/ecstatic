defmodule Test.TestingSystem.DualSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.{OneComponent, AnotherOneComponent}
  use Ecstatic.System

  @impl true
  def aspect() do
    Aspect.new([Test.TestingComponent.OneComponent],[],[every: 1000, for: :infinity])
  end

  @impl true
  def dispatch(entity, _changes, delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, OneComponent)
        |> OneComponent.inc()
        |> OneComponent.frequency(delta)
    c2 = Entity.find_component(entity, AnotherOneComponent)
         |> AnotherOneComponent.dec()
    changes = %Changes{updated: [
                         {Entity.find_component(entity,OneComponent), c},
                         {Entity.find_component(entity,AnotherOneComponent), c2}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c, c2]}
  end
end
