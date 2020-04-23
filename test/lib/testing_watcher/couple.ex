defmodule Test.TestingWatcher.Couple do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, AnotherTestingSystem, TestingComponent, AnotherTestingComponent}

  watch TestingComponent do
    run TestingSystem, [every: 1000, for: :infinity]
  end


  watch AnotherTestingComponent do
    run AnotherTestingSystem, [every: 1000, for: :infinity]
  end
end