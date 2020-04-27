defmodule Test.TestingWatcher.NonReactive.Couple do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.{TestingSystem, TestingComponent}

  watch TestingComponent.One do
    run TestingSystem.One, [every: 1000, for: :infinity]
  end

  watch TestingComponent.AnotherOne do
    run TestingSystem.AnotherOne, [every: 1000, for: :infinity]
  end
end