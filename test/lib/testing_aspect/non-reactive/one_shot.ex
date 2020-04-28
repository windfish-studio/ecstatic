defmodule Test.TestingWatcher.NonReactive.OneShot do
  @moduledoc false
  use Ecstatic.Watcher
  alias Test.TestingSystem.OneSystem
  alias Test.TestingComponent.OneComponent

  watch OneComponent do
    run OneSystem, [every: :continuous, for: 1]
  end
end