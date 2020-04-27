defmodule Test.TestingEntity do
  @moduledoc false
  use Ecstatic.Entity
  alias Test.TestingComponent.{OneComponent, AnotherOneComponent}
  @default_components [OneComponent, AnotherOneComponent]
end
