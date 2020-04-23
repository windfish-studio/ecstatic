defmodule Test.TestingSystem do
  @moduledoc false
  alias Ecstatic.Entity
  alias Test.TestingComponent
  use Ecstatic.System
  require Logger

  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end
  def dispatch(entity, delta) do
    pid = Application.get_env(:ecstatic, :test_pid) #spy
    # TODO test delta
    c = Entity.find_component(entity, TestingComponent)
        |> TestingComponent.inc()

    changes = %Changes{updated: [{Entity.find_component(entity,TestingComponent), c}]}
    Logger.debug(inspect({"monitoring changes: ", changes}))
    Logger.debug(inspect({"monitoring pid: ", pid}))
    send pid, {entity, changes}
    %Changes{updated: [c]}
  end
  #reactive
  def dispatch(entity,changes,delta) do
    nil
  end

  def process(_,_) do
    :ok
  end

end
