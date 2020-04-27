defmodule Test.TestingWatcher.NonReactive.OneSecInfinity do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.OneSystem
  alias Test.TestingComponent.OneComponent

  watch OneComponent do
    run OneSystem, [every: 1000, for: :infinity]
  end
end