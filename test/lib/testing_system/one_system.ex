defmodule Test.TestingSystem.OneSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.OneComponent
  use Ecstatic.System

  @impl true
  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
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