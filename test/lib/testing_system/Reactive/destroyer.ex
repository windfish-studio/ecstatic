defmodule Test.TestingSystem.Reactive.Destroyer do
  alias Ecstatic.Entity
  alias Test.TestingComponent.AnotherOneComponent
  use Ecstatic.System

  @impl true
  #This system reacts to every system that is not self
  def aspect do
    %Ecstatic.Aspect{with: [AnotherOneComponent], trigger_condition: [
      condition: fn _system_m, _entity, changes ->
                    changes.updated
                    |> Enum.filter(fn {_old, new} -> new.type == AnotherOneComponent end)
                    |> Enum.all?(fn {_old, c} -> c.state.var > 0 end)
                    |> Kernel.!()
                 end,
      lifecycle: [:updated]]}
  end

  @impl true
  def dispatch(entity, _changes, _delta \\ 0) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    changes = %Changes{removed: entity.components}
    send pid, {__MODULE__, {entity, changes}}
    Entity.destroy(entity)
    %Changes{}
  end
end
