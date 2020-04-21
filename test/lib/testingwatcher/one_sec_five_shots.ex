defmodule Test.TestingWatcher.OneSecFiveShots do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, TestingComponent}

  watch TestingComponent do
    run TestingSystem, [every: 1000, for: 5]
  end
end