defmodule Test.TestingWatcher.OneSecFiveShots do
  @moduledoc false
  use Ecstatic.Watcher

  alias Test.TestingSystem.One , as: TheSystem
  alias Test.TestingComponent.One, as: TheComponent

  watch TheComponent do
    run TheSystem, [every: 1000, for: 5]
  end
end