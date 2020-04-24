defmodule Reactive do
  @moduledoc false
  alias Test.TestingSystem.One , as: TheSystem
  alias Test.TestingComponent.One, as: TheComponent

  watch TheComponent do
    run TheSystem, when: fn entity, changes -> end
  end
end
