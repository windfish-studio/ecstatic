defmodule Test.TestingWatcher.NonReactive.RealTime do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.One , as: TheSystem
  alias Test.TestingComponent.One, as: TheComponent

  watch TheComponent do
    run TheSystem, [every: :continuous, for: :infinity]
  end
end