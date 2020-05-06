defmodule Test.TestingSystem.AnotherOneSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent.AnotherOneComponent
  use Ecstatic.System

  @impl true
  def aspect do
    %Ecstatic.Aspect{}
  end

  @impl true
  def dispatch(entity,_changes,_delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, AnotherOneComponent)
        |> AnotherOneComponent.dec()
    changes = %Changes{updated: [{Entity.find_component(entity,AnotherOneComponent), c}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c]}
  end
end
