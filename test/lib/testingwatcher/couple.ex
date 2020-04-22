defmodule Test.TestingWatcher.Couple do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, TestingSystem2, TestingComponent, TestingComponent2}

  watch TestingComponent do
    run TestingSystem, [every: 1000, for: :infinity]
  end


  watch TestingComponent2 do
    run TestingSystem2, [every: 1000, for: :infinity]
  end
end