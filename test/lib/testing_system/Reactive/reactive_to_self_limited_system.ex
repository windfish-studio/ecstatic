defmodule Test.TestingSystem.Reactive.ToSelfLimitedSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.OneComponent
  use Ecstatic.System

  @impl true
  #This system reacts to every system that is not self
  def aspect do
    %Ecstatic.Aspect{with: [OneComponent], trigger_condition: [
      condition: fn cause_systems, _entity, changes ->
                    is_this_system = Enum.any?(cause_systems, fn s -> s == __MODULE__ end)
                    case {is_this_system, changes.attached, changes.updated} do
                      {true, _, [{_,new}]} -> new.state.var < 10
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
