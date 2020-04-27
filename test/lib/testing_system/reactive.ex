defmodule Test.TestingSystem.ReactiveSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.{TestingSystem.OneSystem, TestingComponent.OneComponent}
  use Ecstatic.System

  @impl true
  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end

  @impl true
  def dispatch(entity, _changes, _delta \\ 0) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, OneComponent)
        |> OneComponent.x10()
    changes = %Changes{updated: [{Entity.find_component(entity,OneComponent), c}]}
    send pid, {OneSystem, {entity, changes}}
    %Changes{updated: [c]}
  end
end
