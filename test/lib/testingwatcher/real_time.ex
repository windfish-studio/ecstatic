defmodule Test.TestingWatcher.RealTime do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, TestingComponent}

  watch TestingComponent do
    run TestingSystem, [every: :continuous, for: :infinity]
  end
end