defmodule Test.AnotherTestingSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.AnotherTestingComponent
  use Ecstatic.System

  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end

  def dispatch(entity,_changes,_delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    c = Entity.find_component(entity, AnotherTestingComponent)
        |> AnotherTestingComponent.dec()

    changes = %Changes{updated: [{Entity.find_component(entity,AnotherTestingComponent), c}]}
    send pid, {__MODULE__, {entity, changes}}
    %Changes{updated: [c]}
  end
end
