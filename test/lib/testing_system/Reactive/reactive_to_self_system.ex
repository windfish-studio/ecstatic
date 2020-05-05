defmodule Test.TestingSystem.Reactive.ToSelfSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.OneComponent
  use Ecstatic.System

  @impl true
  #This system reacts to every system that is not self
  def aspect do
    %Ecstatic.Aspect{with: [OneComponent], trigger_condition: [
                                              condition: fn cause_systems, _entity, changes ->
                                                      Enum.any?(cause_systems, fn s -> s == __MODULE__ end) ||
                                                        changes.attached != [] end,
                                              lifecycle: [:attached, :updated]]}
  end

  @impl true
  def dispatch(entity, _changes, _delta \\ 0) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, OneComponent)
        |> OneComponent.inc()
    changes = %Changes{updated: [{Entity.find_component(entity,OneComponent), c}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c]}
  end
end
