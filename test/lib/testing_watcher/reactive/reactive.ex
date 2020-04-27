defmodule Test.TestingWatcher.Reactive.Reactive do
  @moduledoc false
  alias Test.TestingSystem.Reactive , as: TheSystem
  alias Test.TestingComponent.One, as: TheComponent
  require Logger

  def watchers do
    [%{
      callback: fn (entity, changes) -> true end,
      component: TheComponent,
      component_lifecycle_hook: :updated,
      system: TheSystem
    }]
  end
end
