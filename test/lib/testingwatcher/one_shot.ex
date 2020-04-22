defmodule Test.TestingWatcher.OneShot do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, TestingComponent}

  watch TestingComponent do
    run TestingSystem, [every: :continuous, for: 1]
  end
end