defmodule Test.TestingWatcher.NonReactive.Couple do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.{OneSystem, AnotherOneSystem}
  alias Test.TestingComponent.{OneComponent, AnotherOneComponent}

  watch OneComponent do
    run OneSystem, [every: 1000, for: :infinity]
  end

  watch AnotherOneComponent do
    run AnotherOneSystem, [every: 1000, for: :infinity]
  end
end