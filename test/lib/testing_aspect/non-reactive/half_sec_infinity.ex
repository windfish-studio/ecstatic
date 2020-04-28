defmodule Test.TestingWatcher.NonReactive.HalfSecInfinity do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.OneSystem
  alias Test.TestingComponent.OneComponent

  watch OneComponent do
    run OneSystem, [every: 500, for: :infinity]
  end
end