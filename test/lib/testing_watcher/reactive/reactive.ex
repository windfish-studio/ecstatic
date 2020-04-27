defmodule Test.TestingWatcher.Reactive.Reactive do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.One , as: TheSystem
  alias Test.TestingComponent.AnotherOne, as: TheComponent
  require Logger

  watch TheComponent do
    #funtion only returns a boolean. It means that it should really run
    run TheSystem, when: fn entity, changes -> true end
  end
end
