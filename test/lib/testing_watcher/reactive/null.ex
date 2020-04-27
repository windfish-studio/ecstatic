defmodule Test.TestingWatcher.Null do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.One , as: TheSystem
  alias Test.TestingComponent.One, as: TheComponent

  watch TheComponent do
    run TheSystem, when: fn entity, changes -> nil end
  end
end
