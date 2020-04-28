defmodule Test.TestingWatcher.NonReactive.OneSecFiveShots do
  @moduledoc false
  use Ecstatic.Watcher

  alias Test.TestingSystem.OneSystem
  alias Test.TestingComponent.OneComponent

  watch OneComponent do
    run OneSystem, [every: 1000, for: 5]
  end
end