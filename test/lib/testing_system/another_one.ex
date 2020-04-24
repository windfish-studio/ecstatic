defmodule Test.TestingSystem.AnotherOne do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent
  use Ecstatic.System

  @impl true
  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end

  @impl true
  def dispatch(entity,_changes,_delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, TestingComponent.AnotherOne)
        |> TestingComponent.AnotherOne.dec()

    changes = %Changes{updated: [{Entity.find_component(entity,TestingComponent.AnotherOne), c}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c]}
  end
end
