defmodule Test.TestingSystem.Reactive.ToUpdatedSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.OneComponent
  use Ecstatic.System
  @impl true
  #This system reacts to every system that is not self
  def aspect do
    %Ecstatic.Aspect{with: [OneComponent], trigger_condition: [
      condition: fn cause_systems, _entity, _changes ->
                                              Enum.any?(cause_systems, fn s -> s != __MODULE__ end)
                                              end,
                                              lifecycle: [:updated]]}
  end

  @impl true
  def dispatch(entity, _changes, _delta \\ 0) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, OneComponent)
        |> OneComponent.x10()
    changes = %Changes{updated: [{Entity.find_component(entity,OneComponent), c}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c]}
  end
end
