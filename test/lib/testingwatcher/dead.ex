defmodule Test.TestingWatcher.Dead do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, TestingComponent}

  watch TestingComponent do
    run TestingSystem, [every: 1000, for: 1]
  end
end