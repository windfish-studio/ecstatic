defmodule Test.TestingWatcher.Reactive.Reactive do
  @moduledoc false
  alias Test.TestingSystem.ReactiveSystem
  alias Test.TestingComponent.OneComponent
  require Logger

  def watchers do
    [%{
      callback: fn (entity, changes) -> true end,
      component: OneComponent,
      component_lifecycle_hook: :updated,
      system: ReactiveSystem
    }]
  end
end
