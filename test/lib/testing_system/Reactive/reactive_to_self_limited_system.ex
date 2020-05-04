defmodule Test.TestingSystem.Reactive.ToSelfLimitedSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.{TestingSystem.OneSystem, TestingComponent.OneComponent}
  use Ecstatic.System

  @impl true
  #This system reacts to every system that is not self
  def aspect do
    aspect = %Ecstatic.Aspect{with: [OneComponent], trigger_condition: [
      condition: fn system_m, _entity, changes ->
                    case {system_m, changes.attached, changes.updated} do
                      {__MODULE__, _, [{_,new}]} -> new.state.var < 10
                      {_, attached, []} ->
                        attached
                        |> Enum.filter(fn c -> c.type == OneComponent end)
                        |> Enum.all?(fn a -> a.state.var < 10 end)
                      _ -> false
                    end
                end,
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
