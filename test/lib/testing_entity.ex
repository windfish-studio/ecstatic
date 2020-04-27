defmodule Test.TestingEntity do
  @moduledoc false
  use Ecstatic.Entity
  alias Test.TestingComponent
  @default_components [TestingComponent.One, TestingComponent.AnotherOne]
end
