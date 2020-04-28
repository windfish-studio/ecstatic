defmodule Test.TestingWatcher.NonReactive.RealTime do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.OneSystem
  alias Test.TestingComponent.OneComponent

  watch OneComponent do
    run OneSystem, [every: :continuous, for: :infinity]
  end
end